USE demo;

-- 创建商品分类表
CREATE TABLE t_goods_category  (
  `id` int ,
  `t_category` varchar(30) ,
  `t_remark` varchar(100) ,
  PRIMARY KEY (`id`)
);



-- 创建商品信息表
CREATE TABLE t_goods (
  `id` int AUTO_INCREMENT,
  `t_category_id` int,
  `t_category` varchar(30),
  `t_name` varchar(50),
  `t_price` DECIMAL(10,2),
  `t_stock` int,
  `t_upper_time` DATETIME,
  PRIMARY KEY (`id`),
  CONSTRAINT foreign_category FOREIGN KEY (`t_category_id`) REFERENCES t_goods_category(`id`)
);


