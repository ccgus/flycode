
foo2 = objc.class("TestClass"):alloc():init()

print(foo2)

foo2:setI(1234)
print(foo2:getI())
foo2:setI2(4321)
print(foo2:getI())

