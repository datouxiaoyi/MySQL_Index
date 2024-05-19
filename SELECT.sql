############################索引的使用场景#################################
--全值匹配
explain select * from t_goods where t_category_id = 1 and t_name = '手机' \G;

--查询范围
explain select * from t_goods where id >= 1 and id <=20 \G;

--匹配最左前缀
explain select * from t_goods where t_name='手机' \G;

--查询索引列
explain select t_name,t_category_id from t_goods where t_name='手机' \G;

--匹配字段前缀
explain select * from t_goods where t_category like '电子%' \G;

--精准与范围匹配查询
explain select * from t_goods where t_category_id=1 and id>=1 and id<=10 \G;

--匹配NULL值
explain select * from t_goods where t_category_id is null \G;

--连接查询匹配索引
explain select goods.t_name,category.t_category from t_goods goods join t_goods_category category on goods.t_category_id = category.id \G;

############################索引避免场景#################################
--以通配符开始的LIKE语句
explain select * from t_goods where t_category like '%电' \G;

--数据类型转换
explain select * from t_goods where t_category = 0 \G;

--OR语句
explain select * from t_goods where t_category_id = 1 or t_stock = 2 \G;

--计算索引列
explain select * from t_goods where left(t_category,2)='电子'\G;

--使用<>或!=操作符匹配查询条件
explain select * from t_goods where t_category<>'电子产品' \G;

--匹配NOT NULL值
explain select * from t_goods where t_category_id is not null \G;

############################索引提示#################################
--使用索引
explain select * from t_goods use index(index_category_name,category_part) where (t_category_id = 1 and t_name='手机' ) or t_category = '电子产品'\G

--忽略索引
explain select * from t_goods ignore index(category_part) where t_category = '电子产品'\G

--强制使用索引
explain select * from t_goods force index(category_part) where t_category = '电子产品'\G