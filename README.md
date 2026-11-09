# VR 透明渲染系统 · Depth Peeling（深度剥离）

Unity 中基于**多 Pass + 模板缓冲 + 深度纹理**实现的深度剥离透明渲染，用于解决半透明物体相互遮挡时的**排序错误**问题，支持 VR 立体渲染（单通道实例化）。

<img src="docs/preview.png" alt="depth peeling preview" width="720">

---

## 1. 解决什么问题

传统 Alpha 混合透明物体在 Unity 中的渲染顺序由 `Queue` + 物体中心到相机的距离决定。当多个半透明物体相互穿插时，这个顺序是错误的，表现为：

- 后面的物体盖住前面的物体
- 同一物体不同面的叠加顺序颠倒
- 透明度叠加深浅不均，出现"色块"

正确做法是**逐像素按深度排序**。Depth Peeling 的思路是：从离相机最近的一层开始，一层一层"剥离"填充，每剥离一层就丢弃更近的片段，直到剥离完所有层。

---

## 2. 实现方案

### 2.1 三层渲染 Pass

| Pass | 名称 | 模板测试 | 深度测试 | ZWrite | 作用 |
|---|---|---|---|---|---|
| 0 | `DEPTH_PEEL_LAYER_1` | `Ref 1 / Comp Always / Pass Replace` | `Less` | On | 渲染最近的透明层，写入模板值 1 |
| 1 | `DEPTH_PEEL_LAYER_2` | `Ref 2 / Comp Equal / Pass Keep` | `Less` | On | 只渲染比第一层更深的片段，写入模板值 2 |
| 2 | `DEPTH_PEEL_LAYER_N` | `Ref 3 / Comp Equal / Pass Keep` | `Less` | Off | 第三层及以上，透明度再衰减 |

### 2.2 关键代码：深度比较

每个 Pass 在片元着色器中读取相机深度纹理，与当前片元的视空间深度比较：

```hlsl
// 获取当前像素的屏幕坐标与场景深度
float2 screenUV = i.screenPos.xy / i.screenPos.w;
float sceneDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, screenUV));

// 第一层：与场景深度相近的片段丢弃（已被不透明物体遮挡）
if (abs(i.eyeDepth - sceneDepth) < _DepthTolerance)
{
    discard;
}
```

第二层改为只渲染**比第一层更深**的片段：

```hlsl
// 第二层：只渲染比第一层更深的片段
if (i.eyeDepth <= sceneDepth)
{
    discard;
}
```

### 2.3 VR 支持

- `UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO` / `UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX`：兼容单通道实例化立体渲染
- `UNITY_VERTEX_INPUT_INSTANCE_ID` + `#pragma multi_compile_instancing`：支持 GPU Instancing
- `Tags { "VREnabled"="True" }`：标记支持 VR

---

## 3. 运行时控制

`DepthPeelingController` 挂在物体上，通过 `MaterialPropertyBlock` 修改材质参数（**不破坏材质实例，避免 Draw Call 增加**）：

```csharp
propertyBlock.SetInt("_LayerCount", layerCount);
propertyBlock.SetFloat("_DepthTolerance", depthTolerance);
propertyBlock.SetFloat("_DepthOffset", depthOffset);
propertyBlock.SetColor("_Color", tintColor);
propertyBlock.SetFloat("_Alpha", alpha);
objectRenderer.SetPropertyBlock(propertyBlock);
```

可调参数（Inspector 中直接可视化）：

| 参数 | 范围 | 说明 |
|---|---|---|
| `layerCount` | 1–4 | 剥离层数 |
| `depthTolerance` | 0.001–0.1 | 深度容差，越大越容易丢弃片段 |
| `depthOffset` | 0.1–2.0 | 深度偏移，缓解深度冲突 |
| `alpha` | 0–1 | 透明度 |
| `tintColor` | — | HDR 颜色 |

同时支持 `[ExecuteAlways]`，**在编辑器非播放状态下也能实时预览参数效果**。

---

## 4. 性能测试

`VRTransparencyTest.cs` 提供自动化压测：

- 在指定区域内随机生成 N 个透明物体（随机位置 / 旋转 / 缩放 / 颜色 / 透明度）
- 为每个物体添加刚体并施加随机冲量与扭矩，制造叠加遮挡
- 按设定间隔输出 **FPS、内存占用、顶点数、三角面数**
- 测试结束后自动清理

```csharp
Debug.Log($"性能监控 - FPS: {fps:F1}, 内存: {memory:F2}MB");
Debug.Log($"渲染统计 - 物体数: {spawnedObjects.Count}, 顶点: {totalVertices}, 三角面: {totalTriangles}");
```

---

## 5. 工程结构

```
VR-Depth-Peeling/
├─ Scripts/
│  ├─ Runtime/
│  │  └─ DepthPeelingController.cs      # 运行时参数控制（MaterialPropertyBlock）
│  └─ Testing/
│     └─ VRTransparencyTest.cs          # 自动化性能测试
├─ Shaders/
│  └─ VRTransparentSystem/
│     ├─ DepthPeelingTransparent.shader # 三层 Pass 深度剥离主 Shader
│     └─ TransparentObject.shader       # 透明物体基础 Shader（含深度偏移）
└─ Scenes/
   └─ VRTransparency.unity              # 演示场景
```

---

## 6. 使用方法

1. 用 **Unity 2022.3 LTS**（或兼容版本）新建 3D 工程
2. 把 `Scripts` 和 `Shaders` 目录拷进 `Assets`
3. 把 `Scenes/VRTransparency.unity` 放入 `Assets/Scenes` 后打开
4. 给透明物体挂上 `DepthPeelingController`，材质使用 `Custom/VR/DepthPeelingTransparent`
5. 调整 Inspector 中的 `layerCount` / `depthTolerance` / `alpha` 观察效果

---

## 7. 已知限制与改进方向

- **固定层数**：当前最多支持 4 层剥离，超出部分统一走 `DEPTH_PEEL_LAYER_N` Pass，精度有限。彻底方案是每剥离完一层拷贝一次深度缓冲（Ping-Pong Framebuffer），代价是每帧多次额外拷贝
- **性能**：剥离层数越多，透明像素的 Overdraw 越高，移动端 VR 需要严格控制层数（建议 2 层）
- **与 URP / HDRP 的兼容**：当前基于 Built-in 渲染管线，URP 需要改用 `RenderPass` + `CommandBuffer` 组织多 Pass

---

## 8. 参考

- Cass Everitt, *Interactive Order-Independent Transparency*, NVIDIA, 2001
- Unity Manual: *Camera's Depth Texture*, *Stencil Buffer*