using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class VRTransparencyTest : MonoBehaviour
{
    [Header("测试设置")]
    public GameObject transparentPrefab;
    public Transform spawnArea;
    public int spawnCount = 5;
    public float testDuration = 10f;

    [Header("性能监控")]
    public bool enablePerformanceLog = true;
    public float logInterval = 2f;

    private List<GameObject> spawnedObjects = new List<GameObject>();
    private float startTime;
    private float lastLogTime;

    void Start()
    {
        if (transparentPrefab == null)
        {
            Debug.LogError("请设置透明物体预制体！");
            return;
        }

        startTime = Time.time;
        lastLogTime = Time.time;

        SpawnTestObjects();
    }

    void Update()
    {
        if (enablePerformanceLog && Time.time - lastLogTime >= logInterval)
        {
            LogPerformanceInfo();
            lastLogTime = Time.time;
        }

        // 测试完成后自动停止
        if (Time.time - startTime > testDuration && testDuration > 0)
        {
            enabled = false;
            Debug.Log("透明度测试完成");
        }
    }

    void SpawnTestObjects()
    {
        if (spawnArea == null)
            spawnArea = transform;

        for (int i = 0; i < spawnCount; i++)
        {
            // 随机位置
            Vector3 randomPos = spawnArea.position +
                new Vector3(
                    Random.Range(-spawnArea.localScale.x / 2, spawnArea.localScale.x / 2),
                    Random.Range(0, spawnArea.localScale.y),
                    Random.Range(-spawnArea.localScale.z / 2, spawnArea.localScale.z / 2)
                );

            // 随机旋转
            Quaternion randomRot = Quaternion.Euler(
                Random.Range(0, 360),
                Random.Range(0, 360),
                Random.Range(0, 360)
            );

            GameObject obj = Instantiate(transparentPrefab, randomPos, randomRot);

            // 随机缩放
            float scale = Random.Range(0.5f, 2f);
            obj.transform.localScale = Vector3.one * scale;

            // 随机颜色和透明度
            Renderer rend = obj.GetComponent<Renderer>();
            if (rend != null)
            {
                Color randomColor = new Color(
                    Random.Range(0.5f, 1f),
                    Random.Range(0.5f, 1f),
                    Random.Range(0.5f, 1f),
                    Random.Range(0.3f, 0.9f)
                );

                if (rend.material != null)
                {
                    rend.material.color = randomColor;
                }
            }

            // 添加随机运动
            Rigidbody rb = obj.AddComponent<Rigidbody>();
            rb.useGravity = false;
            rb.AddForce(Random.onUnitSphere * Random.Range(0.5f, 2f), ForceMode.Impulse);
            rb.AddTorque(Random.onUnitSphere * Random.Range(0.5f, 5f), ForceMode.Impulse);

            spawnedObjects.Add(obj);
        }

        Debug.Log($"生成了 {spawnedObjects.Count} 个透明物体进行测试");
    }

    void LogPerformanceInfo()
    {
        int totalVertices = 0;
        int totalTriangles = 0;

        foreach (GameObject obj in spawnedObjects)
        {
            if (obj != null)
            {
                MeshFilter mf = obj.GetComponent<MeshFilter>();
                if (mf != null && mf.sharedMesh != null)
                {
                    totalVertices += mf.sharedMesh.vertexCount;
                    totalTriangles += mf.sharedMesh.triangles.Length / 3;
                }
            }
        }

        float fps = 1f / Time.deltaTime;
        float memory = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong() / 1024f / 1024f;

        Debug.Log($"性能监控 - FPS: {fps:F1}, 内存: {memory:F2}MB");
        Debug.Log($"渲染统计 - 物体数: {spawnedObjects.Count}, 顶点: {totalVertices}, 三角面: {totalTriangles}");
    }

    void OnDestroy()
    {
        // 清理测试物体
        foreach (GameObject obj in spawnedObjects)
        {
            if (obj != null)
                Destroy(obj);
        }
        spawnedObjects.Clear();
    }

    // 公开接口供测试调用
    public void StartTest()
    {
        Start();
    }

    public void StopTest()
    {
        OnDestroy();
        enabled = false;
    }

    public int GetObjectCount()
    {
        return spawnedObjects.Count;
    }
}