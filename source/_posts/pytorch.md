---
title: "pytorch学习"
date: 2026-05-15

---

参考：https://datawhalechina.github.io/thorough-pytorch/index.html

# 第一章

介绍下ai，ml(垃圾邮件拦截)，dl（猫狗识别）。现在则是llm。
指标介绍：如何评估结果

比如对一个二分类来说。
            实际
          阳性 阴性
预测：阳性  TP  FP
     阴性  FN  TN

overall-accuracy = (TP+TN)/(TP+FP+FN+TN)
average-accuracy = 每一类预测正确的样本/该类总体数量
                 = 1/2* (TP/(TP+FN) + TN/(FP+TN))
kappa系数，一致性检验的指标
recall，召回率 = 实际为正样本并且被正确识别为正样本/实际正样本
              = TP/(TP+FN) 
  即判断模型识别所有正样本的能力
precision，精准率 = 预测正确的正样本/全部预测为正样本 = TP/(TP+FP)

F1 = recall和precision的加权平均 = 2* P*R / (P+R)
PR曲线：对比模型性能。
    曲线一个点就是某个阈值下，模型将大于该阈值的结果判定为正样本。
置信度：大于置信度为正样本
IOU = 交集/并集

AP（average precision）= PR曲线的面积
mAP：所有类AP值的平均值。


# 第二章
推荐uv安装

tensor（张量）就是向量矩阵的推广。

1. 创建: tensor, ones, zeros, arange,linespace, rand，rand
2. 操作：
- 索引，返回与原数据共享内存
```py
import torch
x = torch.rand(4,3)
# 取第二列
print(x[:, 1]) 
print(x[0,:]) #第一行
```
- 维度变化:
    - view, `x.view(-1,6)` -1就是auto的意思。但是只有一个维度可以是-1
    - reshape: 可能会返回view，也可能是拷贝值，
- 广播机制

当形状不同的tensor按元素运算时，可能会触发广播。先复制，再按元素运算
```py
a = torch.arange(0, 3).view(3,1)
b = torch.arange(10, 12).view(1,2)

print(a)
print(b)
print(a+b)

# tensor([[0],
#         [1],
#         [2]])
# tensor([[10, 11]])
# tensor([[10, 11],
#         [11, 12],
#         [12, 13]])
```

- 自动求导+反向传播 autograd

1. y.backward()只是标量，对向量还需要传入向量。
2. 计算图是累加的

```py
x = torch.rand(1,2, requires_grad=True)
y = x ** 2
print(x)
print(y)

y.backward(x)
print(x.grad)
```
# 第三章

1. 数据预处理：1.数据格式统一 2.异常数据消除 3. 划分训练集，验证集，测试集 
2. 选择模型，损失函数和优化方法，对应超参数。
3. 训练，并计算模型表现

## 模型构造训练

- 二维卷积层。模型参数：卷积核+标量偏差。选随机化卷积核再迭代卷积核+偏差。
滑动窗口
- 池化层。直接计算窗口内元素属性。
- 参数初始化
    torch.nn.init
- 损失函数
    - BCE = `-(y*log(p) + (1-y)*log(1-p))` e为底
    - CrossEntropy (x, class) = -log( ( exp(x[class]) )/( sum exp(x[j]) ) ) = -x[class] + log(sum exp(x[j]))
    - L1 = abs(y_pred - y_true)
    Smooth L1 = (sum z_i)/n
    z_i =  0.5(xi-yi)^2 if abs(xi-yi)<1
           abs(xi-yi) - 0.5

    - MSE = (y_pred - y_true)^2
    - PoissonNLL
    - 余弦相似度  衡量方向一致性 loss(x,y) = 1-cos(x1,x2)  if y==1
                                         max(0,cos(x1,x2)-margin ) if y==-1
- 激活函数
    - Sigmoid = 1/(1+e^(-x))
    - tanh 
    - ReLU(x) = max(0, x)
    - GELU = x * Φ(x) 
    - 输出层
        - softmax
        - sigmoid


- 训练
- 优化器 torch.optim, 快速寻找参数
    - SGD 随机梯度下降
    - Momentum，累计历史梯度
    - Adagrad
    - RMSprop
    - Adam， Momentum + RMSprop
    - AdamW

## ResNet

# 第四章

Sequential：更简单串联各个层, 自动实现forward
ModuleList：类似list，需要实现forward函数
ModuleDict：类似ModuleList，需要实现forward函数

# 第五章

模型存储与加载。
没有多卡，GG

# 第六章

1. 自定义损失函数：和定义一层差不多
2. 动态调整学习率：`torch.optim.lr_scheduler`，自定义就是在每次迭代后修改
3. 模型微调：
    1. 在源数据集上预训练一个模型，源模型
    2. clone一个新的模型：目标模型
    3. 为目标模型添加一个输出⼤小为⽬标数据集类别个数的输出层，并随机初始化该层的模型参数。
    4. 在目标数据集上训练目标模型。从头训练输出层，其余层参数都基于源模型微调/

4. 数据增强。 例如imgaug