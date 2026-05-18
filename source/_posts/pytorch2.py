
import torch

# x = torch.rand(4,3)
# print(x)
# x = torch.randn(4,3)
# print(x)

# x = torch.tensor([1,2,3])
# print(x.dtype)

# x = torch.arange(1, 10)
# print(x.dtype
#     )

# x = torch.linspace(0, 10, 3)
# print(x)

# x = torch.randn(4,3)
# print(x)
# print(x[:,1])
# y = x.view(3,4)
# print(y)

# a = torch.arange(0, 3).view(3,1)
# b = torch.arange(10, 12).view(1,2)

# print(a)
# print(b)
# print(a+b)

# x = torch.rand(1,2, requires_grad=True)
# y = x ** 2
# print(x)
# print(y)

# y.backward(x)
# print(x.grad)

from torch import nn 

class MLP(nn.Module):
  # 声明带有模型参数的层，这里声明了两个全连接层
  def __init__(self, **kwargs):
    # 调用MLP父类Block的构造函数来进行必要的初始化。这样在构造实例时还可以指定其他函数
    super(MLP, self).__init__(**kwargs)
    self.hidden = nn.Linear(784, 256)
    self.act = nn.ReLU()
    self.output = nn.Linear(256,10)
    
   # 定义模型的前向计算，即如何根据输入x计算返回所需要的模型输出
  def forward(self, x):
    o = self.act(self.hidden(x))
    return self.output(o)   
  
X = torch.rand(2, 784)
net = MLP()
print(net)
Y = net(X)
print(Y.shape)


def comp_conv2d(conv2d, X):
    # (1, 1)代表批量大小和通道数
    X = X.view((1, 1) + X.shape)
    Y = conv2d(X)
    return Y.view(Y.shape[2:]) # 排除不关心的前两维:批量和通道

conv2d = nn.Conv2d(in_channels=1, out_channels=1, kernel_size=3,padding=1)
print(conv2d)
X = torch.rand(8,8)
Z = comp_conv2d(conv2d, X)
print(Z.shape)

m = nn.Linear(3, 2)
input = torch.randn(4, 3)
output = m(input)
print(input)
print(output)

from torchinfo import summary
resnet18 = m
summary(net, (2,784) ) 

dummy_input = torch.randn(1, 784)

# torch.onnx.export(net, dummy_input, "model.onnx", dynamo=True);

import onnx
try:
   onnx.checker.check_model("model.onnx")
   
except onnx.checker.ValidationError as e:
    print("The model is invalid: %s"%e)
else:
    # 模型可用时，将不会报出异常，并会输出“The model is valid!”
    print("The model is valid!")
