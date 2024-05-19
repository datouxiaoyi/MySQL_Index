# 一、索引的使用场景

## 1、全值匹配

通过主键索引查询

```sql
mysql> explain select * from t_goods where id = 1 \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: const
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 4
          ref: const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

可以看到这里查询数据使用了主键索引。

现在我们再创建一个索引。

```sql
ALTER Table t_goods ADD INDEX index_category_name(t_category_id,t_name);
```

这里为t_category_id与t_name创建了联合索引。

```sql
mysql> explain select * from t_goods where t_category_id = 1 and t_name = '手机' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ref
possible_keys: index_category_name
          key: index_category_name
      key_len: 208
          ref: const,const
         rows: 1
     filtered: 100.00
        Extra: NULL
1 row in set, 1 warning (0.00 sec)
```

这里的查询条件为t_category_id与t_name，所以查询时使用了联合索引index_category_name

## 2、查询范围

对索引的值进行范围查找

```sql
mysql> explain select * from t_goods where id >= 1 and id <=20 \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: range
possible_keys: PRIMARY
          key: PRIMARY
      key_len: 4
          ref: NULL
         rows: 15
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

`type: range`说明根据主键索引范围进行查询。这里 `Extra: Using where`，说明MySQL按照主键确定范围后再回表查询数据。

## 3、匹配最左前缀

解释：也就是说，在使用索引时，MySQL优化器会根据查询条件使用该索引。只有满足这个匹配原则才会使用索引。例如过程创建的联合索引`index_category_name(t_category_id, t_name)`，如果我跳过`t_category_id`直接使用`t_name`条件查询，那么这个查询将不会使用索引。

```sql
mysql> explain select * from t_goods where t_name='手机' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

可以看到这个查询并没有使用索引。

## 4、查询索引列

如果在查询时包含索引的列或者查询的列都在索引中，那么查询的效率会比SELECT * 或者查询没有索引的列的效率要高很多。也就是说，如果查询的列只包含索引列，那么这个效率会高很多。例如

```sql
mysql> explain select t_name,t_category_id from t_goods where t_name='手机' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: index
possible_keys: index_category_name
          key: index_category_name
      key_len: 208
          ref: NULL
         rows: 15
     filtered: 10.00
        Extra: Using where; Using index
1 row in set, 1 warning (0.00 sec)
```

例如这里查询的列都是索引列，所以这个查询的效率会快很多，并且使用了索引。如果有其他不是索引列需要查询，那么这个查询将不会使用索引。例如

```sql
mysql> explain select t_name,t_category_id,t_price from t_goods where t_name='手机' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 10.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

## 5、匹配字段前缀

如果某个字段存储的数据特别长的话，那么在这个字段上建立索引会增加MySQL维护索引的负担。匹配字段前缀就是用于解决这个问题。在字段的开头部分添加索引，按照这个索引进行数据查询。

例如在字段的前10个字符上添加索引，查询时进行匹配。

```sql
mysql> create index category_part on t_goods(t_category(10));
Query OK, 0 rows affected (0.03 sec)
Records: 0  Duplicates: 0  Warnings: 0
```

再次进行模糊匹配查询

```sql
mysql> explain select * from t_goods where t_category like '电子%' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: range
possible_keys: category_part
          key: category_part
      key_len: 43
          ref: NULL
         rows: 5
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

可以看到这里使用了我们刚才创建的索引，这个索引应用于字段的前10个字符。

## 6、精准与范围匹配查询

在查询数据时，可以同时使用两个索引，一个为精准匹配索引，一个为范围匹配索引。例如

```sql
mysql> explain select * from t_goods where t_category_id=1 and id>=1 and id<=10 \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ref
possible_keys: PRIMARY,index_category_name
          key: index_category_name
      key_len: 5
          ref: const
         rows: 5
     filtered: 66.67
        Extra: Using index condition
1 row in set, 1 warning (0.00 sec)
```

这个查询使用了两个索引进行查找，使用`index_category_name`进行精准匹配并且按照主键索引进行范围查询

## 7、匹配NULL值

在查询一个字段时，如果这个字段是索引字段，那么在判断这个字段是否为空时也会使用索引进行查询。例

```sql
mysql> explain select * from t_goods where t_category_id is null \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ref
possible_keys: index_category_name
          key: index_category_name
      key_len: 5
          ref: const
         rows: 1
     filtered: 100.00
        Extra: Using index condition
1 row in set, 1 warning (0.00 sec)
```

这里我查询`t_goods`表中`t_category_id`是`NULL`的字段，可以看到这里是使用了索引进行查找的。

## 8、连接查询匹配索引

在使用JOIN连接语句查询多个数据表中的数据时，如果连接的字段上添加了索引，那么MySQL会使用索引查询数据

```sql
mysql> explain select goods.t_name,category.t_category from t_goods goods join t_goods_category category on goods.t_category_id = category.id \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: category
   partitions: NULL
         type: ALL
possible_keys: PRIMARY
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 5
     filtered: 100.00
        Extra: NULL
*************************** 2. row ***************************
           id: 1
  select_type: SIMPLE
        table: goods
   partitions: NULL
         type: ref
possible_keys: index_category_name
          key: index_category_name
      key_len: 5
          ref: demo.category.id
         rows: 5
     filtered: 100.00
        Extra: Using index
2 rows in set, 1 warning (0.00 sec)
```

在使用`JOIN`联合多表查询时，如果联合的字段是索引字段，那么这个查询也会使用索引列。

# 二、不适合使用索引的场景

## 1、以通配符开始的LIKE语句

在使用LIKE语句时，如果使用通配符%开头，那么MySQL将不会使用索引。例如

```sql
mysql> explain select * from t_goods where t_category like '%电' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 11.11
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

这里的`t_category`字段虽然说是索引字段，但是这里的条件是以通配符`%`开头，所以不会使用索引查询

## 2、数据类型转换

当查询的字段数据进行了数据转换时，也就是说，某个索引字段的类型为字符，但是在匹配条件时，不是字符类型，那么这个查询将不会使用索引查询。例如

```sql
mysql> explain select * from t_goods where t_category = 0 \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: category_part
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 10.00
        Extra: Using where
1 row in set, 3 warnings (0.00 sec)
```

例如这里的查询就没有使用索引，并且`type`的类型为`ALL`，说明进行了全表扫描查询。

## 3、OR语句

在OR语句中如果条件中有不是索引的字段，那么这查询就不会使用索引查询。例如

```sql
mysql> explain select * from t_goods where t_category_id = 1 or t_stock = 2 \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: index_category_name
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 40.00
        Extra: Using where
1 row in set, 1 warning (0.01 sec)
```

这里因为`t_stock`不是索引字段，所以哪怕`t_category_id`索引字段匹配成功，这条语句也不会使用索引查询

## 4、计算索引列

如果在使用索引条件时，这个索引字段进行了计算或者使用了函数，那么此时MySQL是不会使用索引的。

```sql
mysql> explain select * from t_goods where left(t_category,2)='电子'\G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

这里对索引字段`t_category`使用了函数，判断这个字段的前两个字符是否为“电子”。可以看到有15条记录，但是并没有使用索引，哪怕`t_category`是索引列。

## 5、使用<>或!=操作符匹配查询条件

这两个符号都用于表示不等于。当查询条件使用这个时不会使用索引查询。

```sql
mysql> explain select * from t_goods where t_category<>'电子产品' \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: category_part
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

## 6、匹配NOT NULL值

在MySQL中，使用IS NULL来判断索引字段会使用索引查询，但是使用NOT NULL来判断时不会使用索引查询。

```sql

mysql> explain select * from t_goods where t_category_id is not null \G;
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: index_category_name
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

# 三、索引提示

## 1、使用索引

提示MySQL查询优化器使用特定的索引，不需要评估是否使用其他索引。

```sql
mysql> explain select * from t_goods use index(index_category_name,category_part) where (t_category_id = 1 and t_name='手机' ) or t_category = '电子产品'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: index_merge
possible_keys: index_category_name,category_part
          key: index_category_name,category_part
      key_len: 208,43
          ref: NULL
         rows: 6
     filtered: 100.00
        Extra: Using sort_union(index_category_name,category_part); Using where
1 row in set, 1 warning (0.00 sec)
```

这里可以使用`use index()`指定查询时使用特定的索引。但是MySQL仍然可以根据自身的优化器决定是否使用该索引。

## 2、忽略索引

可以在查询时，指定不使用某个索引。

```sql
mysql> explain select * from t_goods ignore index(category_part) where t_category = '电子产品'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ALL
possible_keys: NULL
          key: NULL
      key_len: NULL
          ref: NULL
         rows: 15
     filtered: 33.33
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```

这里使用`ignore index（）`，指定在查询时，忽略指定的索引，使用这条查询没有使用索引，而是进行全表扫描

## 3、强制使用索引

在查询数据时，强制使用某个索引来检索数据。

与`use index()`的区别为，`FORCE INDEX`会强制使用指定的索引，而不会管MySQL的优化器如何选择。

```sql
mysql> explain select * from t_goods force index(category_part) where t_category = '电子产品'\G
*************************** 1. row ***************************
           id: 1
  select_type: SIMPLE
        table: t_goods
   partitions: NULL
         type: ref
possible_keys: category_part
          key: category_part
      key_len: 43
          ref: const
         rows: 5
     filtered: 100.00
        Extra: Using where
1 row in set, 1 warning (0.00 sec)
```