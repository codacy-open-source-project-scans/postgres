-- The gist_page_opaque_info() function prints the page's LSN.
-- Use an unlogged index, so that the LSN is predictable.
CREATE UNLOGGED TABLE test_gist AS SELECT point(i,i) p, i::text t FROM
    generate_series(1,1000) i;
CREATE INDEX test_gist_idx ON test_gist USING gist (p);

-- Page 0 is the root, the rest are leaf pages
SELECT * FROM gist_page_opaque_info(get_raw_page('test_gist_idx', 0));
SELECT * FROM gist_page_opaque_info(get_raw_page('test_gist_idx', 1));
SELECT * FROM gist_page_opaque_info(get_raw_page('test_gist_idx', 2));

SELECT * FROM gist_page_items(get_raw_page('test_gist_idx', 0), 'test_gist_idx');
SELECT * FROM gist_page_items(get_raw_page('test_gist_idx', 1), 'test_gist_idx') LIMIT 5;

-- gist_page_items_bytea prints the raw key data as a bytea. The output of that is
-- platform-dependent (endianness), so omit the actual key data from the output.
SELECT itemoffset, ctid, itemlen FROM gist_page_items_bytea(get_raw_page('test_gist_idx', 0));

-- Suppress the DETAIL message, to allow the tests to work across various
-- page sizes and architectures.
\set VERBOSITY terse

-- Failures with non-GiST index.
CREATE INDEX test_gist_btree on test_gist(t);
SELECT gist_page_items(get_raw_page('test_gist_btree', 0), 'test_gist_btree');
SELECT gist_page_items(get_raw_page('test_gist_btree', 0), 'test_gist_idx');

-- Failure with various modes.
-- invalid page size
SELECT gist_page_items_bytea('aaa'::bytea);
SELECT gist_page_items('aaa'::bytea, 'test_gist_idx'::regclass);
SELECT gist_page_opaque_info('aaa'::bytea);
-- invalid special area size
SELECT * FROM gist_page_opaque_info(get_raw_page('test_gist', 0));
SELECT gist_page_items_bytea(get_raw_page('test_gist', 0));
SELECT gist_page_items_bytea(get_raw_page('test_gist_btree', 0));
\set VERBOSITY default

-- Tests with all-zero pages.
SHOW block_size \gset
SELECT gist_page_items_bytea(decode(repeat('00', :block_size), 'hex'));
SELECT gist_page_items(decode(repeat('00', :block_size), 'hex'), 'test_gist_idx'::regclass);
SELECT gist_page_opaque_info(decode(repeat('00', :block_size), 'hex'));

-- Test gist_page_items with included columns.
-- Non-leaf pages contain only the key attributes, and leaf pages contain
-- the included attributes.
ALTER TABLE test_gist ADD COLUMN i int DEFAULT NULL;
CREATE INDEX test_gist_idx_inc ON test_gist
  USING gist (p) INCLUDE (t, i);
-- Mask the value of the key attribute to avoid alignment issues.
SELECT regexp_replace(keys, '\(p\)=\("(.*?)"\)', '(p)=("<val>")') AS keys_nonleaf_1
  FROM gist_page_items(get_raw_page('test_gist_idx_inc', 0), 'test_gist_idx_inc')
  WHERE itemoffset = 1;
SELECT keys AS keys_leaf_1
  FROM gist_page_items(get_raw_page('test_gist_idx_inc', 1), 'test_gist_idx_inc')
  WHERE itemoffset = 1;

DROP TABLE test_gist;
