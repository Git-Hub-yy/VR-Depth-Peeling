# VR 透明物体渲染（Depth Peeling 深度剥离）

课程设计项目，解决 VR 场景中透明物体渲染顺序错误的问题。

## 技术要点

- Depth Peeling（深度剥离）算法：逐层剥离并渲染透明物体
- 自定义 Shader：`DepthPeelingTransparent.shader`、`TransparentObject.shader`
- 控制器（DepthPeelingController）支持透明度 / 颜色调节与剥离层数配置

## 说明

Unity 项目，Shader 位于 `Shaders/`，控制脚本位于 `Scripts/`。
