# NSArray
##排序
* 逆序，array.reverseObjectEnumerator.allObjects
* 数组中是字符串对象排序首选sortedArrayUsingSelector:
```objective-c
NSArray *array = @[@"John Appleseed", @"Tim Cook", @"Hair Force One", @"Michael Jurewitz"];
NSArray *sortedArray = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
```
* 存储内容是数字
```objective-c
NSArray *numbers = @[@9, @5, @11, @3, @1];
NSArray *sortedNumbers = [numbers sortedArrayUsingSelector:@selector(compare:)];
```
* 使用函数指针sortedArrayHint排序
```objective-c
- (NSData *)sortedArrayHint;
- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
     context:(void *)context;
- (NSArray *)sortedArrayUsingFunction:(NSInteger (*)(id, id, void *))comparator
     context:(void *)context hint:(NSData *)hint;
```
* 基于block的排序方法
```objective-c
- (NSArray *)sortedArrayUsingComparator:(NSComparator)cmptr;
- (NSArray *)sortedArrayWithOptions:(NSSortOptions)opts
     usingComparator:(NSComparator)cmptr;
```
* 性能比较selector最快
```
Sorting 1000000 elements. selector: 4947.90[ms] function: 5618.93[ms] block: 5082.98[ms].
```
* 更快的二分查找
```objective-c
typedef NS_OPTIONS(NSUInteger, NSBinarySearchingOptions) {
     NSBinarySearchingFirstEqual = (1UL << 8),
     NSBinarySearchingLastEqual = (1UL << 9),
     NSBinarySearchingInsertionIndex = (1UL << 10),
};

- (NSUInteger)indexOfObject:(id)obj
     inSortedRange:(NSRange)r
     options:(NSBinarySearchingOptions)opts
     usingComparator:(NSComparator)cmp;

//Time to search for 1000 entries within 1000000 objects. Linear: 54130.38[ms]. Binary: 7.62[ms]
```

## 枚举
* 使用indexesOfObjectsWithOptions:passingTest:
```objective-c
NSIndexSet *indexes = [randomArray indexesOfObjectsWithOptions:NSEnumerationConcurrent
     passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
     return testObj(obj);
}];
NSArray *filteredArray = [randomArray objectsAtIndexes:indexes];
```
* 传统的枚举
```objective-c
NSMutableArray *mutableArray = [NSMutableArray array];
for (id obj in randomArray) {
     if (testObj(obj)) {
          [mutableArray addObject:obj];
     }
}
```
* block方式枚举
```objective-c
NSMutableArray *mutableArray = [NSMutableArray array];
[randomArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
     if (testObj(obj)) {
          [mutableArray addObject:obj];
     }
}];
```
* 通过下标objectAtIndex:
```objective-c
NSMutableArray *mutableArray = [NSMutableArray array];
for (NSUInteger idx = 0; idx < randomArray.count; idx++) {
     id obj = randomArray[idx];
     if (testObj(obj)) {
          [mutableArray addObject:obj];
     }
}
```
* 使用比较传统的学院派NSEnumerator
```objective-c
NSMutableArray *mutableArray = [NSMutableArray array];
NSEnumerator *enumerator = [randomArray objectEnumerator];
id obj = nil;
while ((obj = [enumerator nextObject]) != nil) {
     if (testObj(obj)) {
          [mutableArray addObject:obj];
     }
}
```
* 使用predicate
```objective-c
NSArray *filteredArray2 = [randomArray filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
     return testObj(obj);
}]];
```

* 各个方法枚举时间参考，indexesOfObjectsWithOptions在开启了并发枚举的情况下比NSFastEnumeration快一倍。

| 枚举方法 / 时间 [ms] | 10.000.000 elements | 10.000 elements |
| :------------ |---------------:| -----:|
| indexesOfObjects:, concurrent | 1844.73 | 2.25 |
| NSFastEnumeration (for in) | 3223.45 | 3.21 |
| indexesOfObjects: | 4221.23 | 3.36 |
| enumerateObjectsUsingBlock: | 5459.43 | 5.43 |
| objectAtIndex: | 5282.67 | 5.53 |
| NSEnumerator | 5566.92 | 5.75 |
| filteredArrayUsingPredicate: | 6466.95 | 6.31 |

# NSDictionary
## 性能
同样数目的值，NSDictionary比NSArray要花费多得多的内存空间

## 排序
使用NSArray的排序方法将键数组排序为新的对象
```objective-c
- (NSArray *)keysSortedByValueUsingSelector:(SEL)comparator;
- (NSArray *)keysSortedByValueUsingComparator:(NSComparator)cmptr;
- (NSArray *)keysSortedByValueWithOptions:(NSSortOptions)opts
     usingComparator:(NSComparator)cmptr;
```

## 枚举
* keysOfEntriesWithOptions:passingTest:，可并行
```objective-c
NSSet *matchingKeys = [randomDict keysOfEntriesWithOptions:NSEnumerationConcurrent
passingTest:^BOOL(id key, id obj, BOOL *stop)
{
     return testObj(obj);
}];
NSArray *keys = matchingKeys.allObjects;
NSArray *values = [randomDict objectsForKeys:keys notFoundMarker:NSNull.null];
__unused NSDictionary *filteredDictionary = [NSDictionary dictionaryWithObjects:values
     forKeys:keys];
```
* getObjects:andKeys: 枚举，基于c数组
```objective-c
NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
id __unsafe_unretained objects[numberOfEntries];
id __unsafe_unretained keys[numberOfEntries];
[randomDict getObjects:objects andKeys:keys];
for (int i = 0; i < numberOfEntries; i++) {
     id obj = objects[i];
     id key = keys[i];
     if (testObj(obj)) {
          mutableDictionary[key] = obj;
     }
}
```
* block枚举
```objective-c
NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
[randomDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
     if (testObj(obj)) {
          mutableDictionary[key] = obj;
     }
}];
```
* NSFastEnumeration
```objective-c
NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
for (id key in randomDict) {
     id obj = randomDict[key];
     if (testObj(obj)) {
          mutableDictionary[key] = obj;
     }
}
```
* NSEnumeration
```objective-c
NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
NSEnumerator *enumerator = [randomDict keyEnumerator];
id key = nil;
while ((key = [enumerator nextObject]) != nil) {
     id obj = randomDict[key];
     if (testObj(obj)) {
          mutableDictionary[key] = obj;
     }
}
```
* 各个方法枚举时间参考

| 枚举方法 / 时间 [ms] | 50.000 elements | 1.000.000 elements |
| :------------ |---------------:| -----:|
| keysOfEntriesWithOptions:, concurrent | 16.65 | 425.24 |
| getObjects:andKeys: | 30.33 | 798.49 |
| keysOfEntriesWithOptions: | 30.59 | 856.93 |
| enumerateKeysAndObjectsUsingBlock: | 36.33 | 882.93 |
| NSFastEnumeration | 41.20 | 1043.42 |
| NSEnumeration | 42.21 | 1113.08 |
