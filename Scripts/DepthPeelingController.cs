using UnityEngine;
using System.Collections;

[ExecuteAlways]
[RequireComponent(typeof(Renderer))]
public class DepthPeelingController : MonoBehaviour
{
    [Header("深度剥离设置")]
    [Range(1, 4)] public int layerCount = 2;
    [Range(0.001f, 0.1f)] public float depthTolerance = 0.01f;
    [Range(0.1f, 2.0f)] public float depthOffset = 0.5f;

    [Header("材质属性")]
    [ColorUsage(true, true)] public Color tintColor = Color.white;
    [Range(0, 1)] public float alpha = 0.8f;
    [Range(0, 1)] public float smoothness = 0.5f;
    [Range(0, 1)] public float metallic = 0.0f;

    private Renderer objectRenderer;
    private MaterialPropertyBlock propertyBlock;

    void Start()
    {
        Initialize();
    }

    void OnValidate()
    {
        Initialize();
        UpdateMaterialProperties();
    }

    void Update()
    {
#if UNITY_EDITOR
        if (!Application.isPlaying)
        {
            UpdateMaterialProperties();
        }
#endif
    }

    void Initialize()
    {
        if (objectRenderer == null)
            objectRenderer = GetComponent<Renderer>();

        if (propertyBlock == null)
            propertyBlock = new MaterialPropertyBlock();

        objectRenderer.GetPropertyBlock(propertyBlock);
    }

    void UpdateMaterialProperties()
    {
        if (objectRenderer == null || propertyBlock == null)
            return;

        // 设置深度剥离参数
        propertyBlock.SetInt("_LayerCount", layerCount);
        propertyBlock.SetFloat("_DepthTolerance", depthTolerance);
        propertyBlock.SetFloat("_DepthOffset", depthOffset);

        // 设置材质属性
        propertyBlock.SetColor("_Color", tintColor);
        propertyBlock.SetFloat("_Alpha", alpha);
        propertyBlock.SetFloat("_Glossiness", smoothness);
        propertyBlock.SetFloat("_Metallic", metallic);

        // 应用属性块
        objectRenderer.SetPropertyBlock(propertyBlock);
    }

    // 用于动态更新透明度
    public void SetAlpha(float newAlpha)
    {
        alpha = Mathf.Clamp01(newAlpha);
        UpdateMaterialProperties();
    }

    // 用于动态更新颜色
    public void SetColor(Color newColor)
    {
        tintColor = newColor;
        UpdateMaterialProperties();
    }

    // 切换深度剥离层数
    public void SetLayerCount(int count)
    {
        layerCount = Mathf.Clamp(count, 1, 4);
        UpdateMaterialProperties();
    }

    // 获取当前渲染信息
    public string GetRenderInfo()
    {
        if (objectRenderer == null)
            return "Renderer not found";

        return $"Layers: {layerCount}, Alpha: {alpha:F2}, Depth Tol: {depthTolerance:F3}";
    }
}