--创建联合索引
CREATE INDEX index_category_name ON t_goods (t_category_id, t_name);

--字段前缀索引
CREATE INDEX category_pary ON t_goods(t_category(10))
