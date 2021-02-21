---
title: Objc Runtime 总结
date: 2015-04-01 20:24:27
tags: [runtime, iOS]
categories: Programming
---
# 概述
Objc Runtime使得C具有了面向对象能力，在程序运行时创建，检查，修改类、对象和它们的方法。Runtime是C和汇编编写的，这里<http://www.opensource.apple.com/source/objc4/>可以下到苹果维护的开源代码，GNU也有一个开源的runtime版本，他们都努力的保持一致。[苹果官方的Runtime编程指南](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40008048)

## Runtime函数
Runtime系统是由一系列的函数和数据结构组成的公共接口动态共享库，在/usr/include/objc目录下可以看到头文件，可以用其中一些函数通过C语言实现objectivec中一样的功能。苹果官方文档<https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ObjCRuntimeRef/index.html> 里有详细的Runtime函数文档。

# Class和Object基础数据结构
## Class
objc/runtime.h中objc_class结构体的定义如下：
```C
struct objc_class {
Class isa OBJC_ISA_AVAILABILITY; //isa指针指向Meta Class，因为Objc的类的本身也是一个Object，为了处理这个关系，runtime就创造了Meta Class，当给类发送[NSObject alloc]这样消息时，实际上是把这个消息发给了Class Object

#if !__OBJC2__
Class super_class OBJC2_UNAVAILABLE; // 父类
const char *name OBJC2_UNAVAILABLE; // 类名
long version OBJC2_UNAVAILABLE; // 类的版本信息，默认为0
long info OBJC2_UNAVAILABLE; // 类信息，供运行期使用的一些位标识
long instance_size OBJC2_UNAVAILABLE; // 该类的实例变量大小
struct objc_ivar_list *ivars OBJC2_UNAVAILABLE; // 该类的成员变量链表
struct objc_method_list **methodLists OBJC2_UNAVAILABLE; // 方法定义的链表
struct objc_cache *cache OBJC2_UNAVAILABLE; // 方法缓存，对象接到一个消息会根据isa指针查找消息对象，这时会在methodLists中遍历，如果cache了，常用的方法调用时就能够提高调用的效率。
struct objc_protocol_list *protocols OBJC2_UNAVAILABLE; // 协议链表
#endif

} OBJC2_UNAVAILABLE;
```
objc_ivar_list和objc_method_list的定义
```objectivec
//objc_ivar_list结构体存储objc_ivar数组列表
struct objc_ivar_list {
     int ivar_count OBJC2_UNAVAILABLE;
#ifdef __LP64__
     int space OBJC2_UNAVAILABLE;
#endif
     /* variable length structure */
     struct objc_ivar ivar_list[1] OBJC2_UNAVAILABLE;
} OBJC2_UNAVAILABLE;

//objc_method_list结构体存储着objc_method的数组列表
struct objc_method_list {
     struct objc_method_list *obsolete OBJC2_UNAVAILABLE;
     int method_count OBJC2_UNAVAILABLE;
#ifdef __LP64__
     int space OBJC2_UNAVAILABLE;
#endif
     /* variable length structure */
     struct objc_method method_list[1] OBJC2_UNAVAILABLE;
}
```

## objc_object与id
objc_object是一个类的实例结构体，objc/objc.h中objc_object是一个类的实例结构体定义如下：
```C
struct objc_object {
Class isa OBJC_ISA_AVAILABILITY;
};

typedef struct objc_object *id;
```
向object发送消息时，Runtime库会根据object的isa指针找到这个实例object所属于的类，然后在类的方法列表以及父类方法列表寻找对应的方法运行。id是一个objc_object结构类型的指针，这个类型的对象能够转换成任何一种对象。

## objc_cache
objc_class结构体中的cache字段用于缓存调用过的method。cache指针指向objc_cache结构体，这个结构体的定义如下
```C
struct objc_cache {
unsigned int mask /* total = mask + 1 */ OBJC2_UNAVAILABLE; //指定分配缓存bucket的总数。runtime使用这个字段确定线性查找数组的索引位置
unsigned int occupied OBJC2_UNAVAILABLE; //实际占用缓存bucket总数
Method buckets[1] OBJC2_UNAVAILABLE; //指向Method数据结构指针的数组，这个数组的总数不能超过mask+1，但是指针是可能为空的，这就表示缓存bucket没有被占用，数组会随着时间增长。
};
```

## Meta Class
meta class是一个类对象的类，当向对象发消息，runtime会在这个对象所属类方法列表中查找发送消息对应的方法，但当向类发送消息时，runtime就会在这个类的meta class方法列表里查找。所有的meta class，包括Root class，Superclass，Subclass的isa都指向Root class的meta class，这样能够形成一个闭环。
```objectivec
void TestMetaClass(id self, SEL _cmd) {

     NSLog(@"This objcet is %p", self);
     NSLog(@"Class is %@, super class is %@", [self class], [self superclass]);

     Class currentClass = [self class];
     //
     for (int i = 0; i < 4; i++) {
          NSLog(@"Following the isa pointer %d times gives %p", i, currentClass);
          //通过objc_getClass获得对象isa，这样可以回溯到Root class及NSObject的meta class，可以看到最后指针指向的是0x0和NSObject的meta class类地址一样。
          currentClass = objc_getClass((__bridge void *)currentClass);
     }

     NSLog(@"NSObject's class is %p", [NSObject class]);
     NSLog(@"NSObject's meta class is %p", objc_getClass((__bridge void *)[NSObject class]));
}

@implementation Test
- (void)ex_registerClassPair {

     Class newClass = objc_allocateClassPair([NSError class], "TestClass", 0);
     class_addMethod(newClass, @selector(testMetaClass), (IMP)TestMetaClass, "v@:");
     objc_registerClassPair(newClass);

     id instance = [[newClass alloc] initWithDomain:@"some domain" code:0 userInfo:nil];
     [instance performSelector:@selector(testMetaClass)];
}
@end
```
运行结果
```objectivec
2014-10-20 22:57:07.352 mountain[1303:41490] This objcet is 0x7a6e22b0
2014-10-20 22:57:07.353 mountain[1303:41490] Class is TestStringClass, super class is NSError
2014-10-20 22:57:07.353 mountain[1303:41490] Following the isa pointer 0 times gives 0x7a6e21b0
2014-10-20 22:57:07.353 mountain[1303:41490] Following the isa pointer 1 times gives 0x0
2014-10-20 22:57:07.353 mountain[1303:41490] Following the isa pointer 2 times gives 0x0
2014-10-20 22:57:07.353 mountain[1303:41490] Following the isa pointer 3 times gives 0x0
2014-10-20 22:57:07.353 mountain[1303:41490] NSObject's class is 0xe10000
2014-10-20 22:57:07.354 mountain[1303:41490] NSObject's meta class is 0x0
```

举个例子
```objectivec
@interface Sark : NSObject
@end
@implementation Sark
@end
int main(int argc, const char * argv[]) {
     @autoreleasepool {
          BOOL res1 = [(id)[NSObject class] isKindOfClass:[NSObject class]];
          BOOL res2 = [(id)[NSObject class] isMemberOfClass:[NSObject class]];
          BOOL res3 = [(id)[Sark class] isKindOfClass:[Sark class]];
          BOOL res4 = [(id)[Sark class] isMemberOfClass:[Sark class]];
          NSLog(@"%d %d %d %d", res1, res2, res3, res4);
     }
     return 0;
}

//输出
2014-11-05 14:45:08.474 Test[9412:721945] 1 0 0 0
```
先看看isKindOfClass和isMemberOfClass在Object.mm中的实现
```objectivec
- (BOOL)isKindOf:aClass
{
     Class cls;
     for (cls = isa; cls; cls = cls->superclass)
          if (cls == (Class)aClass)
               return YES;
     return NO;
}

- (BOOL)isMemberOf:aClass
{
     return isa == (Class)aClass;
}
```
res1中，可以从isKindOfClass看出NSObject class的isa第一次会指向NSObject的Meta Class，接着Super class时会NSObject的Meta Class根据前面讲的闭环可以知道是会指到NSObject class，这样res1的bool值就是真了。

res2的话因为是isMemberOf就只有一次，那么是NSObject的Meta Class和NSObject class不同返回的bool值就是false了。

res3第一次是Sark Meta Class，第二次super class 后就是NSObject Meta Class了，返回也是false

res4是Sark Meta Class，所以返回也是false



# 类与对象操作函数
runtime有很多的函数可以操作类和对象。类相关的是class为前缀，对象相关操作是objc或object_为前缀。

## 类相关操作函数

### name
```objectivec
// 获取类的类名
const char * class_getName ( Class cls ); 
```

### super_class和meta-class
```objectivec
// 获取类的父类
Class class_getSuperclass ( Class cls );

// 判断给定的Class是否是一个meta class
BOOL class_isMetaClass ( Class cls );
```

### instance_size
```objectivec
// 获取实例大小
size_t class_getInstanceSize ( Class cls );
```

### 成员变量(ivars)及属性
```objectivec
//成员变量操作函数
// 获取类中指定名称实例成员变量的信息
Ivar class_getInstanceVariable ( Class cls, const char *name );

// 获取类成员变量的信息
Ivar class_getClassVariable ( Class cls, const char *name );

// 添加成员变量
BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types ); //这个只能够向在runtime时创建的类添加成员变量

// 获取整个成员变量列表
Ivar * class_copyIvarList ( Class cls, unsigned int *outCount ); //必须使用free()来释放这个数组

//属性操作函数
// 获取类中指定名称实例成员变量的信息
Ivar class_getInstanceVariable ( Class cls, const char *name );

// 获取类成员变量的信息
Ivar class_getClassVariable ( Class cls, const char *name );

// 添加成员变量
BOOL class_addIvar ( Class cls, const char *name, size_t size, uint8_t alignment, const char *types );

// 获取整个成员变量列表
Ivar * class_copyIvarList ( Class cls, unsigned int *outCount );
```

### methodLists
```objectivec
// 添加方法
BOOL class_addMethod ( Class cls, SEL name, IMP imp, const char *types ); //和成员变量不同的是可以为类动态添加方法。如果有同名会返回NO，修改的话需要使用method_setImplementation

// 获取实例方法
Method class_getInstanceMethod ( Class cls, SEL name );

// 获取类方法
Method class_getClassMethod ( Class cls, SEL name );

// 获取所有方法的数组
Method * class_copyMethodList ( Class cls, unsigned int *outCount );

// 替代方法的实现
IMP class_replaceMethod ( Class cls, SEL name, IMP imp, const char *types );

// 返回方法的具体实现
IMP class_getMethodImplementation ( Class cls, SEL name );
IMP class_getMethodImplementation_stret ( Class cls, SEL name );

// 类实例是否响应指定的selector
BOOL class_respondsToSelector ( Class cls, SEL sel );
```

### objc_protocol_list
```objectivec
// 添加协议
BOOL class_addProtocol ( Class cls, Protocol *protocol );

// 返回类是否实现指定的协议
BOOL class_conformsToProtocol ( Class cls, Protocol *protocol );

// 返回类实现的协议列表
Protocol * class_copyProtocolList ( Class cls, unsigned int *outCount );
```

### version
```objectivec
// 获取版本号
int class_getVersion ( Class cls );

// 设置版本号
void class_setVersion ( Class cls, int version );
```

### 实例
通过实例来消化下上面的那些函数
```objectivec
//-----------------------------------------------------------
// MyClass.h
@interface MyClass : NSObject <NSCopying, NSCoding>
@property (nonatomic, strong) NSArray *array;
@property (nonatomic, copy) NSString *string;
- (void)method1;
- (void)method2;
+ (void)classMethod1;
@end

//-----------------------------------------------------------
// MyClass.m
#import "MyClass.h"
@interface MyClass () {
NSInteger _instance1;
NSString * _instance2;
}
@property (nonatomic, assign) NSUInteger integer;
- (void)method3WithArg1:(NSInteger)arg1 arg2:(NSString *)arg2;
@end

@implementation MyClass
+ (void)classMethod1 {
}

- (void)method1 {
     NSLog(@"call method method1");
}

- (void)method2 {
}

- (void)method3WithArg1:(NSInteger)arg1 arg2:(NSString *)arg2 {
     NSLog(@"arg1 : %ld, arg2 : %@", arg1, arg2);
}

@end

//-----------------------------------------------------------
// main.h

#import "MyClass.h"
#import "MySubClass.h"
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
     @autoreleasepool {
          MyClass *myClass = [[MyClass alloc] init];
          unsigned int outCount = 0;
          Class cls = myClass.class;
          // 类名
          NSLog(@"class name: %s", class_getName(cls));    
          NSLog(@"==========================================================");

          // 父类
          NSLog(@"super class name: %s", class_getName(class_getSuperclass(cls)));
          NSLog(@"==========================================================");

          // 是否是元类
          NSLog(@"MyClass is %@ a meta-class", (class_isMetaClass(cls) ? @"" : @"not"));
          NSLog(@"==========================================================");

          Class meta_class = objc_getMetaClass(class_getName(cls));
          NSLog(@"%s's meta-class is %s", class_getName(cls), class_getName(meta_class));
          NSLog(@"==========================================================");

          // 变量实例大小
          NSLog(@"instance size: %zu", class_getInstanceSize(cls));
          NSLog(@"==========================================================");

          // 成员变量
          Ivar *ivars = class_copyIvarList(cls, &outCount);
          for (int i = 0; i < outCount; i++) {
               Ivar ivar = ivars[i];
               NSLog(@"instance variable's name: %s at index: %d", ivar_getName(ivar), i);
          }

          free(ivars);

          Ivar string = class_getInstanceVariable(cls, "_string");
          if (string != NULL) {
               NSLog(@"instace variable %s", ivar_getName(string));
          }

          NSLog(@"==========================================================");

          // 属性操作
          objc_property_t * properties = class_copyPropertyList(cls, &outCount);
          for (int i = 0; i < outCount; i++) {
               objc_property_t property = properties[i];
               NSLog(@"property's name: %s", property_getName(property));
          }

          free(properties);

          objc_property_t array = class_getProperty(cls, "array");
          if (array != NULL) {
               NSLog(@"property %s", property_getName(array));
          }

          NSLog(@"==========================================================");

          // 方法操作
          Method *methods = class_copyMethodList(cls, &outCount);
          for (int i = 0; i < outCount; i++) {
               Method method = methods[i];
               NSLog(@"method's signature: %s", method_getName(method));
          }

          free(methods);

          Method method1 = class_getInstanceMethod(cls, @selector(method1));
          if (method1 != NULL) {
               NSLog(@"method %s", method_getName(method1));
          }

          Method classMethod = class_getClassMethod(cls, @selector(classMethod1));
          if (classMethod != NULL) {
               NSLog(@"class method : %s", method_getName(classMethod));
          }

          NSLog(@"MyClass is%@ responsd to selector: method3WithArg1:arg2:", class_respondsToSelector(cls, @selector(method3WithArg1:arg2:)) ? @"" : @" not");

          IMP imp = class_getMethodImplementation(cls, @selector(method1));
          imp();

          NSLog(@"==========================================================");

          // 协议
          Protocol * __unsafe_unretained * protocols = class_copyProtocolList(cls, &outCount);
          Protocol * protocol;
          for (int i = 0; i < outCount; i++) {
               protocol = protocols[i];
               NSLog(@"protocol name: %s", protocol_getName(protocol));
          }

          NSLog(@"MyClass is%@ responsed to protocol %s", class_conformsToProtocol(cls, protocol) ? @"" : @" not", protocol_getName(protocol));

          NSLog(@"==========================================================");
     }
     return 0;
}
```
输出结果
```objectivec
2014-10-22 19:41:37.452 RuntimeTest[3189:156810] class name: MyClass
2014-10-22 19:41:37.453 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.454 RuntimeTest[3189:156810] super class name: NSObject
2014-10-22 19:41:37.454 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.454 RuntimeTest[3189:156810] MyClass is not a meta-class
2014-10-22 19:41:37.454 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.454 RuntimeTest[3189:156810] MyClass's meta-class is MyClass
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] instance size: 48
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] instance variable's name: _instance1 at index: 0
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] instance variable's name: _instance2 at index: 1
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] instance variable's name: _array at index: 2
2014-10-22 19:41:37.455 RuntimeTest[3189:156810] instance variable's name: _string at index: 3
2014-10-22 19:41:37.463 RuntimeTest[3189:156810] instance variable's name: _integer at index: 4
2014-10-22 19:41:37.463 RuntimeTest[3189:156810] instace variable _string
2014-10-22 19:41:37.463 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.463 RuntimeTest[3189:156810] property's name: array
2014-10-22 19:41:37.463 RuntimeTest[3189:156810] property's name: string
2014-10-22 19:41:37.464 RuntimeTest[3189:156810] property's name: integer
2014-10-22 19:41:37.464 RuntimeTest[3189:156810] property array
2014-10-22 19:41:37.464 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.464 RuntimeTest[3189:156810] method's signature: method1
2014-10-22 19:41:37.464 RuntimeTest[3189:156810] method's signature: method2
2014-10-22 19:41:37.464 RuntimeTest[3189:156810] method's signature: method3WithArg1:arg2:
2014-10-22 19:41:37.465 RuntimeTest[3189:156810] method's signature: integer
2014-10-22 19:41:37.465 RuntimeTest[3189:156810] method's signature: setInteger:
2014-10-22 19:41:37.465 RuntimeTest[3189:156810] method's signature: array
2014-10-22 19:41:37.465 RuntimeTest[3189:156810] method's signature: string
2014-10-22 19:41:37.465 RuntimeTest[3189:156810] method's signature: setString:
2014-10-22 19:41:37.465 RuntimeTest[3189:156810] method's signature: setArray:
2014-10-22 19:41:37.466 RuntimeTest[3189:156810] method's signature: .cxx_destruct
2014-10-22 19:41:37.466 RuntimeTest[3189:156810] method method1
2014-10-22 19:41:37.466 RuntimeTest[3189:156810] class method : classMethod1
2014-10-22 19:41:37.466 RuntimeTest[3189:156810] MyClass is responsd to selector: method3WithArg1:arg2:
2014-10-22 19:41:37.467 RuntimeTest[3189:156810] call method method1
2014-10-22 19:41:37.467 RuntimeTest[3189:156810] ==========================================================
2014-10-22 19:41:37.467 RuntimeTest[3189:156810] protocol name: NSCopying
2014-10-22 19:41:37.467 RuntimeTest[3189:156810] protocol name: NSCoding
2014-10-22 19:41:37.467 RuntimeTest[3189:156810] MyClass is responsed to protocol NSCoding
2014-10-22 19:41:37.468 RuntimeTest[3189:156810] ======================================
```

## 动态创建类和对象
### 动态创建类
```objectivec
// 创建一个新类和元类
Class objc_allocateClassPair ( Class superclass, const char *name, size_t extraBytes ); //如果创建的是root class，则superclass为Nil。extraBytes通常为0

// 销毁一个类及其相关联的类
void objc_disposeClassPair ( Class cls ); //在运行中还存在或存在子类实例，就不能够调用这个。

// 在应用中注册由objc_allocateClassPair创建的类
void objc_registerClassPair ( Class cls ); //创建了新类后，然后使用class_addMethod，class_addIvar函数为新类添加方法，实例变量和属性后再调用这个来注册类，再之后就能够用了。
```
使用实例
```objectivec
Class cls = objc_allocateClassPair(MyClass.class, "MySubClass", 0);
class_addMethod(cls, @selector(submethod1), (IMP)imp_submethod1, "v@:");
class_replaceMethod(cls, @selector(method1), (IMP)imp_submethod1, "v@:");
class_addIvar(cls, "_ivar1", sizeof(NSString *), log(sizeof(NSString *)), "i");

objc_property_attribute_t type = {"T", "@\"NSString\""};
objc_property_attribute_t ownership = { "C", "" };
objc_property_attribute_t backingivar = { "V", "_ivar1"};
objc_property_attribute_t attrs[] = {type, ownership, backingivar};

class_addProperty(cls, "property2", attrs, 3);
objc_registerClassPair(cls);

id instance = [[cls alloc] init];
[instance performSelector:@selector(submethod1)];
[instance performSelector:@selector(method1)];
```
输出
```objectivec
2014-10-23 11:35:31.006 RuntimeTest[3800:66152] run sub method 1
2014-10-23 11:35:31.006 RuntimeTest[3800:66152] run sub method 1
```

### 动态创建对象
```objectivec
// 创建类实例
id class_createInstance ( Class cls, size_t extraBytes ); //会在heap里给类分配内存。这个方法和+alloc方法类似。

// 在指定位置创建类实例
id objc_constructInstance ( Class cls, void *bytes ); 

// 销毁类实例
void * objc_destructInstance ( id obj ); //不会释放移除任何相关引用
```
测试下效果
```objectivec
//可以看出class_createInstance和alloc的不同
id theObject = class_createInstance(NSString.class, sizeof(unsigned));
id str1 = [theObject init];
NSLog(@"%@", [str1 class]);
id str2 = [[NSString alloc] initWithString:@"test"];
NSLog(@"%@", [str2 class]);
```
输出结果
```objectivec
2014-10-23 12:46:50.781 RuntimeTest[4039:89088] NSString
2014-10-23 12:46:50.781 RuntimeTest[4039:89088] __NSCFConstantString
```

## 实例操作函数
这些函数是针对创建的实例对象的一系列操作函数。
### 整个对象操作的函数
```objectivec
// 返回指定对象的一份拷贝
id object_copy ( id obj, size_t size );
// 释放指定对象占用的内存
id object_dispose ( id obj );
```
应用场景
```objectivec
//把a转换成占用更多空间的子类b
NSObject *a = [[NSObject alloc] init];
id newB = object_copy(a, class_getInstanceSize(MyClass.class));
object_setClass(newB, MyClass.class);
object_dispose(a);
```

### 对象实例变量进行操作的函数
```objectivec
// 修改类实例的实例变量的值
Ivar object_setInstanceVariable ( id obj, const char *name, void *value );
// 获取对象实例变量的值
Ivar object_getInstanceVariable ( id obj, const char *name, void **outValue );
// 返回指向给定对象分配的任何额外字节的指针
void * object_getIndexedIvars ( id obj );
// 返回对象中实例变量的值
id object_getIvar ( id obj, Ivar ivar );
// 设置对象中实例变量的值
void object_setIvar ( id obj, Ivar ivar, id value );
```

### 对对象类操作
```objectivec
// 返回给定对象的类名
const char * object_getClassName ( id obj );
// 返回对象的类
Class object_getClass ( id obj );
// 设置对象的类
Class object_setClass ( id obj, Class cls );
```

## 获取类定义
```objectivec
// 获取已注册的类定义的列表
int objc_getClassList ( Class *buffer, int bufferCount );

// 创建并返回一个指向所有已注册类的指针列表
Class * objc_copyClassList ( unsigned int *outCount );

// 返回指定类的类定义
Class objc_lookUpClass ( const char *name );
Class objc_getClass ( const char *name );
Class objc_getRequiredClass ( const char *name );

// 返回指定类的元类
Class objc_getMetaClass ( const char *name );
```
演示如何使用
```objectivec
int numClasses;
Class * classes = NULL;
numClasses = objc_getClassList(NULL, 0);

if (numClasses > 0) {
     classes = malloc(sizeof(Class) * numClasses);
     numClasses = objc_getClassList(classes, numClasses);
     NSLog(@"number of classes: %d", numClasses);

     for (int i = 0; i < numClasses; i++) {
          Class cls = classes[i];
          NSLog(@"class name: %s", class_getName(cls));
     }
     free(classes);
}
```
结果如下：
```objectivec
2014-10-23 16:20:52.589 RuntimeTest[8437:188589] number of classes: 1282
2014-10-23 16:20:52.589 RuntimeTest[8437:188589] class name: DDTokenRegexp
2014-10-23 16:20:52.590 RuntimeTest[8437:188589] class name: _NSMostCommonKoreanCharsKeySet
2014-10-23 16:20:52.590 RuntimeTest[8437:188589] class name: OS_xpc_dictionary
2014-10-23 16:20:52.590 RuntimeTest[8437:188589] class name: NSFileCoordinator
2014-10-23 16:20:52.590 RuntimeTest[8437:188589] class name: NSAssertionHandler
2014-10-23 16:20:52.590 RuntimeTest[8437:188589] class name: PFUbiquityTransactionLogMigrator
2014-10-23 16:20:52.591 RuntimeTest[8437:188589] class name: NSNotification
2014-10-23 16:20:52.591 RuntimeTest[8437:188589] class name: NSKeyValueNilSetEnumerator
2014-10-23 16:20:52.591 RuntimeTest[8437:188589] class name: OS_tcp_connection_tls_session
2014-10-23 16:20:52.591 RuntimeTest[8437:188589] class name: _PFRoutines
......还有大量输出
```

# 成员变量与属性
## 基础数据类型
### Ivar
实例变量类型，指向objc_ivar结构体的指针，ivar指针地址是根据class结构体的地址加上基地址偏移字节得到的。
```objectivec
typedef struct objc_ivar *Ivar;

struct objc_ivar {
char *ivar_name OBJC2_UNAVAILABLE; // 变量名
char *ivar_type OBJC2_UNAVAILABLE; // 变量类型
int ivar_offset OBJC2_UNAVAILABLE; // 基地址偏移字节
#ifdef __LP64__
int space OBJC2_UNAVAILABLE;
#endif
}
```

### objc_property_t
属性类型，指向objc_property结构体
```objectivec
typedef struct objc_property *objc_property_t;
```
通过class_copyPropertyList和protocol_copyPropertyList方法获取类和协议的属性
```objectivec
objc_property_t *class_copyPropertyList(Class cls, unsigned int *outCount)
objc_property_t *protocol_copyPropertyList(Protocol *proto, unsigned int *outCount)
```
示例
```objectivec
@interface Lender : NSObject {
     float alone;
}
@property float alone;
@end

//获取属性列表
id LenderClass = objc_getClass("Lender");
unsigned int outCount;
objc_property_t *properties = class_copyPropertyList(LenderClass, &outCount);

//查找属性名称
const char *property_getName(objc_property_t property)

//通过给出的名称来在类和协议中获取属性的引用
objc_property_t class_getProperty(Class cls, const char *name)
objc_property_t protocol_getProperty(Protocol *proto, const char *name, BOOL isRequiredProperty, BOOL isInstanceProperty)

//发掘属性名称和@encode类型字符串
const char *property_getAttributes(objc_property_t property)

//从一个类中获取它的属性
id LenderClass = objc_getClass("Lender");
unsigned int outCount, i;
objc_property_t *properties = class_copyPropertyList(LenderClass, &outCount);
for (i = 0; i < outCount; i++) {
     objc_property_t property = properties[i];
     fprintf(stdout, "%s %s\n", property_getName(property), property_getAttributes(property));
}
```

### objc_property_attribute_t
也是结构体，定义属性的attribute
```objectivec
typedef struct {
     const char *name; // 特性名
     const char *value; // 特性值
} objc_property_attribute_t;
```

### 示例
下面代码会编译出错，Runtime Crash还是正常输出
```objectivec
@interface Sark : NSObject
@property (nonatomic, copy) NSString *name;
@end
@implementation Sark
- (void)speak
{
     NSLog(@"my name is %@", self.name);
}
@end
@interface Test : NSObject
@end
@implementation Test
- (instancetype)init
{
     self = [super init];
     if (self) {
          id cls = [Sark class];
          void *obj = &cls;
          [(__bridge id)obj speak];
     }
     return self;
}
@end
int main(int argc, const char * argv[]) {
     @autoreleasepool {
          [[Test alloc] init];
     }
     return 0;
}

//结果正常输出
2014-11-07 14:08:25.698 Test[1097:57255] my name is
```
obj为指向Sark Class的指针，相当于Sark的实例对象但是还是不一样，根据objc_msgSend流程，obj指针能够在方法列表中找到speak方法，所以运行正常。

为了得到self.name能够输出的原因，可以加入调试代码
```objectivec
- (void)speak
{
     unsigned int numberOfIvars = 0;
     Ivar *ivars = class_copyIvarList([self class], &numberOfIvars);
     for(const Ivar *p = ivars; p < ivars+numberOfIvars; p++) {
          Ivar const ivar = *p;
          ptrdiff_t offset = ivar_getOffset(ivar);
          const char *name = ivar_getName(ivar);
          NSLog(@"Sark ivar name = %s, offset = %td", name, offset);
     }
     NSLog(@"my name is %p", &_name);
     NSLog(@"my name is %@", *(&_name));
}
@implementation Test
- (instancetype)init
{
     self = [super init];
     if (self) {
          NSLog(@"Test instance = %@", self);
          void *self2 = (__bridge void *)self;
          NSLog(@"Test instance pointer = %p", &self2);
          id cls = [Sark class];
          NSLog(@"Class instance address = %p", cls);
          void *obj = &cls;
          NSLog(@"Void *obj = %@", obj);
          [(__bridge id)obj speak];
     }
     return self;
}
@end
//输出
2014-11-11 00:56:02.464 Test[10475:1071029] Test instance = 2014-11-11 00:56:02.464 Test[10475:1071029] Test instance pointer = 0x7fff5fbff7c8
2014-11-11 00:56:02.465 Test[10475:1071029] Class instance address = 0x1000023c8
2014-11-11 00:56:02.465 Test[10475:1071029] Void *obj = 2014-11-11 00:56:02.465 Test[10475:1071029] Sark ivar name = _name, offset = 8
2014-11-11 00:56:02.465 Test[10475:1071029] my name is 0x7fff5fbff7c8
2014-11-11 00:56:02.465 Test[10475:1071029] my name is
```
Sark中Propertyname会被转换成ivar到类的结构里，runtime会计算ivar的地址偏移来找ivar的最终地址，根据输出可以看出Sark class的指针地址加上ivar的偏移量正好跟Test对象指针地址。

## 关联对象
关联对象是在运行时添加的类似成员。
```objectivec
//将一个对象连接到其它对象
static char myKey;
objc_setAssociatedObject(self, &myKey, anObject, OBJC_ASSOCIATION_RETAIN);
//获取一个新的关联的对象
id anObject = objc_getAssociatedObject(self, &myKey);
//使用objc_removeAssociatedObjects函数移除一个关联对象
```
实例演示关联对象使用
```objectivec
//动态的将一个Tap手势操作连接到任何UIView中。
- (void)setTapActionWithBlock:(void (^)(void))block
{
     UITapGestureRecognizer *gesture = objc_getAssociatedObject(self, &kDTActionHandlerTapGestureKey);

     if (!gesture)
     {
          gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(__handleActionForTapGesture:)];
          [self addGestureRecognizer:gesture];
          //将创建的手势对象和block作为关联对象
          objc_setAssociatedObject(self, &kDTActionHandlerTapGestureKey, gesture, OBJC_ASSOCIATION_RETAIN);
     }

     objc_setAssociatedObject(self, &kDTActionHandlerTapBlockKey, block, OBJC_ASSOCIATION_COPY);
}

//手势识别对象的target和action
- (void)__handleActionForTapGesture:(UITapGestureRecognizer *)gesture
{
     if (gesture.state == UIGestureRecognizerStateRecognized)
     {
          void(^action)(void) = objc_getAssociatedObject(self, &kDTActionHandlerTapBlockKey);

          if (action)
          {
               action();
          }
     }
}
```

## 成员变量和属性的操作方法

### 成员变量
```objectivec
// 获取成员变量名
const char * ivar_getName ( Ivar v );
// 获取成员变量类型编码
const char * ivar_getTypeEncoding ( Ivar v );
// 获取成员变量的偏移量
ptrdiff_t ivar_getOffset ( Ivar v );
```

### Associated Objects
```objectivec
// 设置关联对象
void objc_setAssociatedObject ( id object, const void *key, id value, objc_AssociationPolicy policy );
// 获取关联对象
id objc_getAssociatedObject ( id object, const void *key );
// 移除关联对象
void objc_removeAssociatedObjects ( id object );

//上面方法以键值对的形式动态的向对象添加，获取或者删除关联值。其中关联政策是一组枚举常量。这些常量对应着引用关联值机制，也就是Objc内存管理的引用计数机制。
enum {
     OBJC_ASSOCIATION_ASSIGN = 0,
     OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
     OBJC_ASSOCIATION_COPY_NONATOMIC = 3,
     OBJC_ASSOCIATION_RETAIN = 01401,
     OBJC_ASSOCIATION_COPY = 01403
};
```

### 属性
```objectivec
// 获取属性名
const char * property_getName ( objc_property_t property );
// 获取属性特性描述字符串
const char * property_getAttributes ( objc_property_t property );
// 获取属性中指定的特性
char * property_copyAttributeValue ( objc_property_t property, const char *attributeName );
// 获取属性的特性列表
objc_property_attribute_t * property_copyAttributeList ( objc_property_t property, unsigned int *outCount );
```

## 实例
两个接口同样数据不同的字段名处理
```objectivec
@interface MyObject: NSObject

@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * status;

@end

//返回字典数据有不同的字段名，一般是写两个方法，但是如果灵活用runtime只用写一个方法
@{@"name1": "张三", @"status1": @"start"}
@{@"name2": "张三", @"status2": @"end"}
//定义一个映射字典（全局）
static NSMutableDictionary *map = nil;

@implementation MyObject

+ (void)load
{
map = [NSMutableDictionary dictionary];

map[@"name1"] = @"name";
map[@"status1"] = @"status";
map[@"name2"] = @"name";
map[@"status2"] = @"status";
}

@end

//不同字段映射到MyObject相同属性上
- (void)setDataWithDic:(NSDictionary *)dic
{
     [dic enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {

          NSString *propertyKey = [self propertyForKey:key];
          if (propertyKey)
          {
               objc_property_t property = class_getProperty([self class], [propertyKey UTF8String]);

               // TODO: 针对特殊数据类型做处理
               NSString *attributeString = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
               ...
               [self setValue:obj forKey:propertyKey];
          }
     }];
}
```

# Method和消息

## Method和消息的基础数据类型

### SEL
选择器表示一个方法的selector的指针，可以理解为Method中的ID类型
```objectivec
typedef struct objc_selector *SEL;
//objc_selector编译时会根据每个方法名字参数序列生成唯一标识
SEL sel1 = @selector(method1);
NSLog(@"sel : %p", sel1);
输出
2014-10-30 18:40:07.518 RuntimeTest[52734:466626] sel : 0x100002d72
```
获取SEL的三个方法：
* sel_registerName函数
* objectivec编译器提供的@selector()
* NSSelectorFromString()方法

### IMP
是函数指针，指向方法的首地址，通过SEL快速得到对应IMP，这时可以跳过Runtime消息传递机制直接执行函数，比直接向对象发消息高效。定义如下
```objectivec
id (*IMP)(id, SEL, ...)
```

### Method
用于表示类定义中的方法
```objectivec
typedef struct objc_method *Method;

struct objc_method {
     SEL method_name OBJC2_UNAVAILABLE; // 方法名
     char *method_types OBJC2_UNAVAILABLE; //是个char指针，存储着方法的参数类型和返回值类型
     IMP method_imp OBJC2_UNAVAILABLE; // 方法实现，函数指针
}
```

## Method相关操作函数

### Method
```objectivec
// 调用指定方法的实现，返回的是方法实现时的返回，参数receiver不能为空，这个比method_getImplementation和method_getName快
id method_invoke ( id receiver, Method m, ... );
// 调用返回一个数据结构的方法的实现
void method_invoke_stret ( id receiver, Method m, ... );
// 获取方法名，希望获得方法明的C字符串，使用sel_getName(method_getName(method))
SEL method_getName ( Method m );
// 返回方法的实现
IMP method_getImplementation ( Method m );
// 获取描述方法参数和返回值类型的字符串
const char * method_getTypeEncoding ( Method m );
// 获取方法的返回值类型的字符串
char * method_copyReturnType ( Method m );
// 获取方法的指定位置参数的类型字符串
char * method_copyArgumentType ( Method m, unsigned int index );
// 通过引用返回方法的返回值类型字符串
void method_getReturnType ( Method m, char *dst, size_t dst_len );
// 返回方法的参数的个数
unsigned int method_getNumberOfArguments ( Method m );
// 通过引用返回方法指定位置参数的类型字符串
void method_getArgumentType ( Method m, unsigned int index, char *dst, size_t dst_len );
// 返回指定方法的方法描述结构体
struct objc_method_description * method_getDescription ( Method m );
// 设置方法的实现
IMP method_setImplementation ( Method m, IMP imp );
// 交换两个方法的实现
void method_exchangeImplementations ( Method m1, Method m2 );
```

### Method的SEL
```objectivec
// 返回给定选择器指定的方法的名称
const char * sel_getName ( SEL sel );
// 在objectivec Runtime系统中注册一个方法，将方法名映射到一个选择器，并返回这个选择器
SEL sel_registerName ( const char *str );
// 在objectivec Runtime系统中注册一个方法
SEL sel_getUid ( const char *str );
// 比较两个选择器
BOOL sel_isEqual ( SEL lhs, SEL rhs );
```

## Method调用流程
消息函数，Objc中发送消息是用中括号把接收者和消息括起来，只到运行时才会把消息和方法实现绑定。
```objectivec
//这个函数将消息接收者和方法名作为基础参数。消息发送给一个对象时，objc_msgSend通过对象的isa指针获得类的结构体，先在Cache里找，找到就执行，没找到就在分发列表里查找方法的selector，没找到就通过objc_msgSend结构体中指向父类的指针找到父类，然后在父类分发列表找，直到root class（NSObject）。
objc_msgSend(receiver, selector, arg1, arg2, ...)
```
编译器会根据情况在objc_msgSend，objc_msgSend_stret，objc_msgSendSuper，或objc_msgSendSuper_stret四个方法中选一个调用。如果是传递给超类就会调用带super的函数，如果返回是数据结构而不是一个值就会调用带stret的函数。在i386平台返回类型为浮点消息会调用objc_msgSend_fpret函数。

举个例子，NSStringFromClass([self class])和NSStringFromClass([super class])输出都是self的类名。原因如下

调用[self class]的时候先调用objc_msgSend，发现self没有class这个方法，然后用objc_msgSendSuper就去父类找，还是没有，继续用objc_msgSendSuper到NSObject里找，结果找到了，查找NSObject中class方法的runtime源码会发现它会返回self，所以[self class]会返回self本身。同理[super class]相对前者就是少了objc_msgSend这一步，最后也会找到NSObject根类里的class方法，自然结果也是返回了self。

### Method中的接收消息对象参数和方法选择器参数
在Method中使用self关键字来引用实例本身，self的内容即接收消息的对象是在Method运行时被传入的同时还有方法选择器。

### 获取Method地址
使用NSObject提供的methodForSelector:方法可以获得Method的指针，通过指针调用实现代码。
```objectivec
void (*setter)(id, SEL, BOOL);
int i;
setter = (void (*)(id, SEL, BOOL))[target
     methodForSelector:@selector(setFilled:)];
for ( i = 0 ; i < 1000 ; i++ )
     setter(targetList[i], @selector(setFilled:), YES);
```
## Method转发
如果使用[object message]调用方法，object无法响应message时就会报错。用performSelector...调用就要等到运行时才确定是否能接受，不能才崩溃。
```objectivec
//先调用respondsToSelector:来判断一下
if ([self respondsToSelector:@selector(method)]) {
     [self performSelector:@selector(method)];
}
```
Method转发机制分为三步：

### 动态方法解析
```objectivec
void functionForMethod1(id self, SEL _cmd) {
     NSLog(@"%@, %p", self, _cmd);
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
     NSString *selectorString = NSStringFromSelector(sel);
     if ([selectorString isEqualToString:@"method1"]) {
          class_addMethod(self.class, @selector(method1), (IMP)functionForMethod1, "@:");
     }
     return [super resolveInstanceMethod:sel];
}
```
可以动态的提供一个方法的实现。例如可以用@dynamic关键字在类的实现文件中写个属性
```objectivec
//这个表明会为这个属性动态提供set get方法，就是编译器是不会默认生成setPropertyName:和propertyName方法，需要动态提供。可以通过重载resolveInstanceMethod:和resolveClassMethod:方法分别添加实例方法和类方法实现。最后用class_addMethod完成添加特定方法实现的操作
@dynamic propertyName;

//
void dynamicMethodIMP(id self, SEL _cmd) {
     // implementation ....
}
@implementation MyClass
+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
     if (aSEL == @selector(resolveThisMethodDynamically)) {
          //v@:表示返回值和参数，可以在苹果官网查看Type Encoding相关文档 https://developer.apple.com/library/mac/DOCUMENTATION/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
          class_addMethod([self class], aSEL, (IMP) dynamicMethodIMP, "v@:");
          return YES;
     }
     return [super resolveInstanceMethod:aSEL];
}
@end
```

### 重定向接收者
如果无法处理消息会继续调用下面的方法，同时在这里Runtime系统实际上是给了一个替换消息接收者的机会，但是替换的对象千万不要是self，那样会进入死循环。
```objectivec
- (id)forwardingTargetForSelector:(SEL)aSelector
{
     if(aSelector == @selector(mysteriousMethod:)){
          return alternateObject;
     }
     return [super forwardingTargetForSelector:aSelector];
}
```
使用这个方法通常在对象内部，如下
```objectivec
@interface SUTRuntimeMethodHelper : NSObject
- (void)method2;
@end

@implementation SUTRuntimeMethodHelper
- (void)method2 {
     NSLog(@"%@, %p", self, _cmd);
}
@end

#pragma mark -
@interface SUTRuntimeMethod () {
     SUTRuntimeMethodHelper *_helper;
}
@end

@implementation SUTRuntimeMethod
+ (instancetype)object {
     return [[self alloc] init];
}

- (instancetype)init {
     self = [super init];
     if (self != nil) {
          _helper = [[SUTRuntimeMethodHelper alloc] init];
     }
     return self;
}

- (void)test {
     [self performSelector:@selector(method2)];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
     NSLog(@"forwardingTargetForSelector");
     NSString *selectorString = NSStringFromSelector(aSelector);

     // 将消息转发给_helper来处理
     if ([selectorString isEqualToString:@"method2"]) {
          return _helper;
     }
     return [super forwardingTargetForSelector:aSelector];
}
@end
```

### 最后进行转发
如果以上两种都没法处理未知消息就需要完整消息转发了。调用如下方法
```objectivec
//这一步是最后机会将消息转发给其它对象，对象会将未处理的消息相关的selector，target和参数都封装在anInvocation中。forwardInvocation:像未知消息分发中心，将未知消息转发给其它对象。注意的是forwardInvocation:方法只有在消息接收对象无法正常响应消息时才被调用。
- (void)forwardInvocation:(NSInvocation *)anInvocation
//必须重写这个方法，消息转发使用这个方法获得的信息创建NSInvocation对象。
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
```
范例
```objectivec
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
     NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];

     if (!signature) {
          if ([SUTRuntimeMethodHelper instancesRespondToSelector:aSelector]) {
               signature = [SUTRuntimeMethodHelper instanceMethodSignatureForSelector:aSelector];
          }
     }
     return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
     if ([SUTRuntimeMethodHelper instancesRespondToSelector:anInvocation.selector]) {
          [anInvocation invokeWithTarget:_helper];
     }
}
```

### 转发和多继承
转发和继承相似，一个Object把消息转发出去就好像它继承了另一个Object的方法一样。

### Message消息的参考文章
* Message forwarding <https://mikeash.com/pyblog/friday-qa-2009-03-27-objectivec-message-forwarding.html>
* objectivec messaging <https://www.mikeash.com/pyblog/friday-qa-2009-03-20-objectivec-messaging.html>
* The faster objc_msgSend <http://www.mulle-kybernetik.com/artikel/Optimization/opti-9.html>

## Method Swizzling
是改变一个selector实际实现的技术，可以在运行时修改selector对应的函数来修改Method的实现。前面的消息转发很强大，但是需要能够修改对应类的源码，但是对于有些类无法修改其源码时又要更改其方法实现时可以使用Method Swizzling，通过重新映射方法来达到目的，但是跟消息转发比起来调试会困难。

### 使用method swizzling需要注意的问题
* Swizzling应该总在+load中执行：objectivec在运行时会自动调用类的两个方法+load和+initialize。+load会在类初始加载时调用，和+initialize比较+load能保证在类的初始化过程中被加载
* Swizzling应该总是在dispatch_once中执行：swizzling会改变全局状态，所以在运行时采取一些预防措施，使用dispatch_once就能够确保代码不管有多少线程都只被执行一次。这将成为method swizzling的最佳实践。
* Selector，Method和Implementation：这几个之间关系可以这样理解，一个类维护一个运行时可接收的消息分发表，分发表中每个入口是一个Method，其中key是一个特定的名称，及SEL，与其对应的实现是IMP即指向底层C函数的指针。


举例说明如何使用Method Swizzling对一个类中注入一些我们的新的操作。
```objectivec
#import <objc/runtime.h>

@implementation UIViewController (Tracking)

+ (void)load {
     static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
          Class class = [self class];
          // When swizzling a class method, use the following:
          // Class class = object_getClass((id)self);
          
          //通过method swizzling修改了UIViewController的@selector(viewWillAppear:)的指针使其指向了自定义的xxx_viewWillAppear
          SEL originalSelector = @selector(viewWillAppear:);
          SEL swizzledSelector = @selector(xxx_viewWillAppear:);

          Method originalMethod = class_getInstanceMethod(class, originalSelector);
          Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

          BOOL didAddMethod = class_addMethod(class,
               originalSelector,
               method_getImplementation(swizzledMethod),
               method_getTypeEncoding(swizzledMethod));
          
          //如果类中不存在要替换的方法，就先用class_addMethod和class_replaceMethod函数添加和替换两个方法实现。但如果已经有了要替换的方法，就调用method_exchangeImplementations函数交换两个方法的Implementation。
          if (didAddMethod) {
               class_replaceMethod(class,
                    swizzledSelector,
                    method_getImplementation(originalMethod),
               method_getTypeEncoding(originalMethod));
          } else {
               method_exchangeImplementations(originalMethod, swizzledMethod);
          }
     });
}

#pragma mark - Method Swizzling
- (void)xxx_viewWillAppear:(BOOL)animated {
     [self xxx_viewWillAppear:animated];
     NSLog(@"viewWillAppear: %@", self);
}

@end
```
method_exchangeImplementations做的事情和如下代码是一样的
```objectivec
IMP imp1 = method_getImplementation(m1);
IMP imp2 = method_getImplementation(m2);
method_setImplementation(m1, imp2);
method_setImplementation(m2, imp1);
```
另一种Method Swizzling的实现
```objectivec
- (void)replacementReceiveMessage:(const struct BInstantMessage *)arg1 {
     NSLog(@"arg1 is %@", arg1);
     [self replacementReceiveMessage:arg1];
}
+ (void)load {
     SEL originalSelector = @selector(ReceiveMessage:);
     SEL overrideSelector = @selector(replacementReceiveMessage:);
     Method originalMethod = class_getInstanceMethod(self, originalSelector);
     Method overrideMethod = class_getInstanceMethod(self, overrideSelector);
     if (class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
          class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
     } else {
          method_exchangeImplementations(originalMethod, overrideMethod);
     }
}
```
这里有几个关于Method Swizzling的资源可以参考
* How do I implement method swizzling? <http://stackoverflow.com/questions/5371601/how-do-i-implement-method-swizzling>
* Method Swizzling <http://nshipster.com/method-swizzling/>
* What are the Dangers of Method Swizzling in Objective C? <http://stackoverflow.com/questions/5339276/what-are-the-dangers-of-method-swizzling-in-objectivec>
* JRSwizzle <https://github.com/rentzsch/jrswizzle>

# Protocol和Category

## 基础数据类型

### Category
指向分类的结构体的指针
```objectivec
typedef struct objc_category *Category;

struct objc_category {
     char *category_name OBJC2_UNAVAILABLE; // 分类名
     char *class_name OBJC2_UNAVAILABLE; // 分类所属的类名
     struct objc_method_list *instance_methods OBJC2_UNAVAILABLE; // 实例方法列表
     struct objc_method_list *class_methods OBJC2_UNAVAILABLE; // 类方法列表，Meta Class方法列表的子集
     struct objc_protocol_list *protocols OBJC2_UNAVAILABLE; // 分类所实现的协议列表
}
```
Category里面的方法加载过程，objc源码中找到objc-os.mm，函数_objc_init就是runtime的加载入口由libSystem调用，开始初始化，之后objc-runtime-new.mm里的map_images会加载map到内存，_read_images开始初始化这个map，这时会load所有Class，Protocol和Category，NSObject的+load方法就是这个时候调用的。下面是加载代码
```objectivec
// Discover categories.
for (EACH_HEADER) {
     category_t **catlist = _getObjc2CategoryList(hi, &count);
     for (i = 0; i < count; i++) {
          category_t *cat = catlist[i];
          Class cls = remapClass(cat->cls);
          if (!cls) {
               // Category's target class is missing (probably weak-linked).
               // Disavow any knowledge of this category.
               catlist[i] = nil;
               if (PrintConnecting) {
                    _objc_inform("CLASS: IGNORING category \?\?\?(%s) %p with "
                         "missing weak-linked target class",
                         cat->name, cat);
               }
               continue;
          }
          // Process this category.
          // First, register the category with its target class.
          // Then, rebuild the class's method lists (etc) if
          // the class is realized.
          BOOL classExists = NO;
          if (cat->instanceMethods || cat->protocols || cat->instanceProperties)
          {
               addUnattachedCategoryForClass(cat, cls, hi);
               if (cls->isRealized()) {
                    remethodizeClass(cls);
                    classExists = YES;
               }
               if (PrintConnecting) {
                    _objc_inform("CLASS: found category -%s(%s) %s",
                         cls->nameForLogging(), cat->name,
                         classExists ? "on existing class" : "");
               }
          }
          if (cat->classMethods || cat->protocols /* || cat->classProperties */)
          {
               addUnattachedCategoryForClass(cat, cls->ISA(), hi);
               if (cls->ISA()->isRealized()) {
                    remethodizeClass(cls->ISA());
               }
               if (PrintConnecting) {
                    _objc_inform("CLASS: found category +%s(%s)",
                         cls->nameForLogging(), cat->name);
               }
          }
     }
}

//调用remethodizeClass方法，在其实现里调用attachCategoryMethods
static void
attachCategoryMethods(Class cls, category_list *cats, bool flushCaches)
{
     if (!cats) return;
     if (PrintReplacedMethods) printReplacements(cls, cats);
     bool isMeta = cls->isMetaClass();
     method_list_t **mlists = (method_list_t **)
          _malloc_internal(cats->count * sizeof(*mlists));
     // Count backwards through cats to get newest categories first
     int mcount = 0;
     int i = cats->count;
     BOOL fromBundle = NO;
     while (i--) {
          method_list_t *mlist = cat_method_list(cats->list[i].cat, isMeta);
          if (mlist) {
               mlists[mcount++] = mlist;
               fromBundle |= cats->list[i].fromBundle;
          }
     }
     attachMethodLists(cls, mlists, mcount, NO, fromBundle, flushCaches);
     _free_internal(mlists);
}
```
示例，下面的代码会编译错误，Runtime Crash还是会正常输出
```objectivec
@interface NSObject (Sark)
+ (void)foo;
@end
@implementation NSObject (Sark)
- (void)foo
{
     NSLog(@"IMP: -[NSObject(Sark) foo]");
}
@end
int main(int argc, const char * argv[]) {
     @autoreleasepool {
          [NSObject foo];
          [[NSObject new] foo];
     }
     return 0;
}
//结果，正常输出结果如下
2014-11-06 13:11:46.694 Test[14872:1110786] IMP: -[NSObject(Sark) foo]
2014-11-06 13:11:46.695 Test[14872:1110786] IMP: -[NSObject(Sark) foo]
```
objc runtime加载后NSObject的Sark Category被加载，头文件+(void)foo没有IMP，只会出现一个warning。被加到Class的Method list里的方法只有-(void)foo，Meta Class的方法列表里没有。

执行[NSObject foo]时，会在Meta Class的Method list里找，找不着就继续往super class里找，NSObject Meta Clas的super class是NSObject本身，这时在NSObject的Method list里就有foo这个方法了，能够正常输出。

执行[[NSObject new] foo]就简单的多了，[NSObject new]生成一个实例，实例的Method list是有foo方法的，于是正常输出。


### Protocol
Protocol其实就是一个对象结构体
```objectivec
typedef struct objc_object Protocol;
```

## 操作函数
Category操作函数信息都包含在objc_class中，我们可以通过objc_class的操作函数来获取分类的操作函数信息。
```objectivec
@interface RuntimeCategoryClass : NSObject
- (void)method1;
@end

@interface RuntimeCategoryClass (Category)
- (void)method2;
@end

@implementation RuntimeCategoryClass
- (void)method1 {
}

@end

@implementation RuntimeCategoryClass (Category)
- (void)method2 {
}

@end

#pragma mark -
NSLog(@"测试objc_class中的方法列表是否包含分类中的方法");
unsigned int outCount = 0;
Method *methodList = class_copyMethodList(RuntimeCategoryClass.class, &outCount);

for (int i = 0; i < outCount; i++) {
     Method method = methodList[i];

     const char *name = sel_getName(method_getName(method));

     NSLog(@"RuntimeCategoryClass's method: %s", name);

     if (strcmp(name, sel_getName(@selector(method2)))) {
          NSLog(@"分类方法method2在objc_class的方法列表中");
     }
}

//输出
2014-11-08 10:36:39.213 [561:151847] 测试objc_class中的方法列表是否包含分类中的方法
2014-11-08 10:36:39.215 [561:151847] RuntimeCategoryClass's method: method2
2014-11-08 10:36:39.215 [561:151847] RuntimeCategoryClass's method: method1
2014-11-08 10:36:39.215 [561:151847] 分类方法method2在objc_class的方法列表中
```
Runtime提供了Protocol的一系列函数操作，函数包括
```objectivec
// 返回指定的协议
Protocol * objc_getProtocol ( const char *name );
// 获取运行时所知道的所有协议的数组
Protocol ** objc_copyProtocolList ( unsigned int *outCount );
// 创建新的协议实例
Protocol * objc_allocateProtocol ( const char *name );
// 在运行时中注册新创建的协议
void objc_registerProtocol ( Protocol *proto ); //创建一个新协议后必须使用这个进行注册这个新协议，但是注册后不能够再修改和添加新方法。
// 为协议添加方法
void protocol_addMethodDescription ( Protocol *proto, SEL name, const char *types, BOOL isRequiredMethod, BOOL isInstanceMethod );
// 添加一个已注册的协议到协议中
void protocol_addProtocol ( Protocol *proto, Protocol *addition );
// 为协议添加属性
void protocol_addProperty ( Protocol *proto, const char *name, const objc_property_attribute_t *attributes, unsigned int attributeCount, BOOL isRequiredProperty, BOOL isInstanceProperty );
// 返回协议名
const char * protocol_getName ( Protocol *p );
// 测试两个协议是否相等
BOOL protocol_isEqual ( Protocol *proto, Protocol *other );
// 获取协议中指定条件的方法的方法描述数组
struct objc_method_description * protocol_copyMethodDescriptionList ( Protocol *p, BOOL isRequiredMethod, BOOL isInstanceMethod, unsigned int *outCount );
// 获取协议中指定方法的方法描述
struct objc_method_description protocol_getMethodDescription ( Protocol *p, SEL aSel, BOOL isRequiredMethod, BOOL isInstanceMethod );
// 获取协议中的属性列表
objc_property_t * protocol_copyPropertyList ( Protocol *proto, unsigned int *outCount );
// 获取协议的指定属性
objc_property_t protocol_getProperty ( Protocol *proto, const char *name, BOOL isRequiredProperty, BOOL isInstanceProperty );
// 获取协议采用的协议
Protocol ** protocol_copyProtocolList ( Protocol *proto, unsigned int *outCount );
// 查看协议是否采用了另一个协议
BOOL protocol_conformsToProtocol ( Protocol *proto, Protocol *other );
```

# Block
runtime中一些支持block操作的函数
```objectivec
// 创建一个指针函数的指针，该函数调用时会调用特定的block
IMP imp_implementationWithBlock ( id block );

// 返回与IMP(使用imp_implementationWithBlock创建的)相关的block
id imp_getBlock ( IMP anImp );

// 解除block与IMP(使用imp_implementationWithBlock创建的)的关联关系，并释放block的拷贝
BOOL imp_removeBlock ( IMP anImp );
```
测试代码
```objectivec
@interface MyRuntimeBlock : NSObject

@end

@implementation MyRuntimeBlock

@end

IMP imp = imp_implementationWithBlock(^(id obj, NSString *str) {
     NSLog(@"%@", str);
});
class_addMethod(MyRuntimeBlock.class, @selector(testBlock:), imp, "v@:@");
MyRuntimeBlock *runtime = [[MyRuntimeBlock alloc] init];
[runtime performSelector:@selector(testBlock:) withObject:@"hello world!"];

//结果
2014-11-09 14:03:19.779 [1172:395446] hello world!
```

# Runtime的应用
## 获取系统提供的库相关信息
主要函数
```objectivec
// 获取所有加载的objectivec框架和动态库的名称
const char ** objc_copyImageNames ( unsigned int *outCount );

// 获取指定类所在动态库
const char * class_getImageName ( Class cls );

// 获取指定库或框架中所有类的类名
const char ** objc_copyClassNamesForImage ( const char *image, unsigned int *outCount );
```
通过这些函数就能够获取某个类所有的库，以及某个库中包含哪些类
```objectivec
NSLog(@"获取指定类所在动态库");

NSLog(@"UIView's Framework: %s", class_getImageName(NSClassFromString(@"UIView")));

NSLog(@"获取指定库或框架中所有类的类名");
const char ** classes = objc_copyClassNamesForImage(class_getImageName(NSClassFromString(@"UIView")), &outCount);
for (int i = 0; i < outCount; i++) {
     NSLog(@"class name: %s", classes[i]);
}

//结果
2014-11-08 12:57:32.689 [747:184013] 获取指定类所在动态库
2014-11-08 12:57:32.690 [747:184013] UIView's Framework: /System/Library/Frameworks/UIKit.framework/UIKit
2014-11-08 12:57:32.690 [747:184013] 获取指定库或框架中所有类的类名
2014-11-08 12:57:32.691 [747:184013] class name: UIKeyboardPredictiveSettings
2014-11-08 12:57:32.691 [747:184013] class name: _UIPickerViewTopFrame
2014-11-08 12:57:32.691 [747:184013] class name: _UIOnePartImageView
2014-11-08 12:57:32.692 [747:184013] class name: _UIPickerViewSelectionBar
2014-11-08 12:57:32.692 [747:184013] class name: _UIPickerWheelView
2014-11-08 12:57:32.692 [747:184013] class name: _UIPickerViewTestParameters
......
```

## 对App的用户行为进行追踪
就是用户点击时把事件记录下来。一般比较做法就是在viewDidAppear里记录事件，这样会让这样记录事件的代码遍布整个项目中。继承或类别也会有问题。这时利用Method Swizzling把一个方法的实现和另一个方法的实现进行替换。
```objectivec
//先定义一个类别，添加要Swizzled的方法
@implementation UIViewController (Logging)- (void)swizzled_viewDidAppear:(BOOL)animated
{ // call original implementation
     [self swizzled_viewDidAppear:animated]; // Logging
     [Logging logWithEventName:NSStringFromClass([self class])];
}
//接下来实现swizzle方法
@implementation UIViewController (Logging)void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) { // the method might not exist in the class, but in its superclass
     Method originalMethod = class_getInstanceMethod(class, originalSelector);
     Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector); // class_addMethod will fail if original method already exists
     BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)); // the method doesn’t exist and we just added one
     if (didAddMethod) {
          class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
     }
     else {
          method_exchangeImplementations(originalMethod, swizzledMethod);
     }
}

//最后要确保在程序启动的时候调用swizzleMethod方法在之前的UIViewController的Logging类别里添加+load:方法，然后在+load:里把viewDidAppear替换掉
@implementation UIViewController (Logging)+ (void)load
{
     swizzleMethod([self class], @selector(viewDidAppear:), @selector(swizzled_viewDidAppear:));
}

//更简化直接用新的IMP取代原IMP，不是替换，只需要有全局的函数指针指向原IMP即可。
void (gOriginalViewDidAppear)(id, SEL, BOOL);void newViewDidAppear(UIViewController *self, SEL _cmd, BOOL animated)
{ // call original implementation
     gOriginalViewDidAppear(self, _cmd, animated); // Logging
     [Logging logWithEventName:NSStringFromClass([self class])];
}
+ (void)load
{
     Method originalMethod = class_getInstanceMethod(self, @selector(viewDidAppear:));
     gOriginalViewDidAppear = (void *)method_getImplementation(originalMethod); if(!class_addMethod(self, @selector(viewDidAppear:), (IMP) newViewDidAppear, method_getTypeEncoding(originalMethod))) {
          method_setImplementation(originalMethod, (IMP) newViewDidAppear);
     }
}
```
通过Method Swizzling可以把事件代码或Logging，Authentication，Caching等跟主要业务逻辑代码解耦。这种处理方式叫做Cross Cutting Concerns<http://en.wikipedia.org/wiki/Cross-cutting_concern> 用Method Swizzling动态给指定的方法添加代码解决Cross Cutting Concerns的编程方式叫Aspect Oriented Programming <http://en.wikipedia.org/wiki/Aspect-oriented_programming> 目前有些第三方库可以很方便的使用AOP，比如Aspects <https://github.com/steipete/Aspects> 这里是使用Aspects的范例<https://github.com/okcomp/AspectsDemo>
