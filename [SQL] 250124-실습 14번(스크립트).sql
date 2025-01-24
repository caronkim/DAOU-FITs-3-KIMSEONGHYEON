-- 통계치를 해당 세션에 한해서만 레벨 제한 해제
ALTER SESSION SET STATISTICS_LEVEL=ALL;


-- 1.
-- 원래 쿼리
SELECT * FROM EMPLOYEES
WHERE EMP_NO LIKE '101%'
    OR EMP_NO LIKE '103%'
ORDER BY EMP_NO;

-- SCHEMA 관찰
SELECT * FROM EMPLOYEES;

-- 튜닝
SELECT * FROM EMPLOYEES
    WHERE EMP_NO BETWEEN 10100 AND 10199
UNION ALL
SELECT * FROM EMPLOYEES
    WHERE EMP_NO BETWEEN 10300 AND 10399;

-- 2.
-- 원래 쿼리
SELECT NVL(GENDER, 'NON') AS GENDER, COUNT(*)
FROM EMPLOYEES
GROUP BY NVL(GENDER, 'NON');

SELECT * FROM EMPLOYEES;

SELECT index_name, table_name, uniqueness
FROM user_indexes
WHERE table_name = 'EMPLOYEES';

-- 튜닝
SELECT /*+INDEX(EMPLOYEES IDX_GENDER)*/GENDER, COUNT(*)
FROM EMPLOYEES
GROUP BY GENDER;

-- 3.
-- 원래 쿼리
SELECT * FROM EMPLOYEES
WHERE GENDER || ' ' || LAST_NAME = 'M Radwan';
-----------------------------------------------------------------------------------------
| Id  | Operation         | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |      1 |        |      5 |00:00:00.01 |     143 |
|*  1 |  TABLE ACCESS FULL| EMPLOYEES |      1 |      8 |      5 |00:00:00.01 |     143 |
-----------------------------------------------------------------------------------------

-- 스키마 및 인덱스 조회
SELECT * FROM EMPLOYEES;
SELECT INDEX_NAME, TABLE_NAME, UNIQUENESS
FROM USER_INDEXES
WHERE TABLE_NAME = 'EMPLOYEES';

-- 튜닝
SELECT /*+INDEX(EMPLOYEES IDX_GENDER_LAST_NAME)*/* FROM EMPLOYEES
WHERE GENDER = 'M' AND LAST_NAME = 'Radwan';
----------------------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name                 | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
----------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                      |      1 |        |      5 |00:00:00.01 |       7 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMPLOYEES            |      1 |      8 |      5 |00:00:00.01 |       7 |
|*  2 |   INDEX RANGE SCAN                  | IDX_GENDER_LAST_NAME |      1 |      8 |      5 |00:00:00.01 |       2 |
----------------------------------------------------------------------------------------------------------------------

SELECT * FROM EMPLOYEES
WHERE GENDER = 'M' AND LAST_NAME = 'Radwan';

-- 4.
-- 원래 쿼리
SELECT FIRST_NAME, LAST_NAME, EMP_NO
FROM EMPLOYEES
WHERE SUBSTR(EMP_NO, 1, 4) = 1030;
-----------------------------------------------------------------------------------------
| Id  | Operation         | Name      | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-----------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |           |      1 |        |     10 |00:00:00.01 |     143 |
|*  1 |  TABLE ACCESS FULL| EMPLOYEES |      1 |      3 |     10 |00:00:00.01 |     143 |
-----------------------------------------------------------------------------------------

-- 스키마 확인
SELECT * FROM EMPLOYEES;

-- 튜닝
SELECT FIRST_NAME, LAST_NAME, EMP_NO
FROM EMPLOYEES
WHERE EMP_NO >= 10300
    AND EMP_NO < 10310;
-------------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name        | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |             |      1 |        |     10 |00:00:00.01 |       3 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| EMPLOYEES   |      1 |     10 |     10 |00:00:00.01 |       3 |
|*  2 |   INDEX RANGE SCAN                  | SYS_C008394 |      1 |     10 |     10 |00:00:00.01 |       2 |
-------------------------------------------------------------------------------------------------------------

-- 5.
-- 원래 쿼리
SELECT DISTINCT E.EMP_NO, E.FIRST_NAME, E.LAST_NAME, D.DEPT_NO
FROM EMPLOYEES E, DEPT_MANAGER D
WHERE E.EMP_NO = D.EMP_NO;
-------------------------------------------------------------------------------------------------------
| Id  | Operation                     | Name        | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
-------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT              |             |      1 |        |     24 |00:00:00.01 |      51 |
|   1 |  HASH UNIQUE                  |             |      1 |     24 |     24 |00:00:00.01 |      51 |
|   2 |   NESTED LOOPS                |             |      1 |     24 |     24 |00:00:00.01 |      51 |
|   3 |    NESTED LOOPS               |             |      1 |     24 |     24 |00:00:00.01 |      27 |
|   4 |     INDEX FAST FULL SCAN      | SYS_C008382 |      1 |     24 |     24 |00:00:00.01 |       4 |
|*  5 |     INDEX UNIQUE SCAN         | SYS_C008394 |     24 |      1 |     24 |00:00:00.01 |      23 |
|   6 |    TABLE ACCESS BY INDEX ROWID| EMPLOYEES   |     24 |      1 |     24 |00:00:00.01 |      24 |
-------------------------------------------------------------------------------------------------------

-- 튜닝
SELECT /*+ORDERED USE_NL(D)*/E.EMP_NO, E.FIRST_NAME, E.LAST_NAME, D.DEPT_NO
FROM DEPT_MANAGER D, EMPLOYEES E
WHERE E.EMP_NO = D.EMP_NO;
------------------------------------------------------------------------------------------------------
| Id  | Operation                    | Name        | Starts | E-Rows | A-Rows |   A-Time   | Buffers |
------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT             |             |      1 |        |     24 |00:00:00.01 |      51 |
|   1 |  NESTED LOOPS                |             |      1 |     24 |     24 |00:00:00.01 |      51 |
|   2 |   NESTED LOOPS               |             |      1 |     24 |     24 |00:00:00.01 |      27 |
|   3 |    INDEX FAST FULL SCAN      | SYS_C008382 |      1 |     24 |     24 |00:00:00.01 |       4 |
|*  4 |    INDEX UNIQUE SCAN         | SYS_C008394 |     24 |      1 |     24 |00:00:00.01 |      23 |
|   5 |   TABLE ACCESS BY INDEX ROWID| EMPLOYEES   |     24 |      1 |     24 |00:00:00.01 |      24 |
------------------------------------------------------------------------------------------------------

-- 6.
-- 원래 쿼리
SELECT COUNT(DISTINCT E.EMP_NO) AS CNT
FROM EMPLOYEES E, (
    SELECT EMP_NO
    FROM SALARIES
    WHERE SALARY > 50000
    ) S
WHERE E.EMP_NO = S.EMP_NO;
-----------------------------------------------------------------------------------------------------------------------------
| Id  | Operation                | Name        | Starts | E-Rows | A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
-----------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT         |             |      1 |        |      1 |00:00:00.01 |     934 |       |       |          |
|   1 |  SORT AGGREGATE          |             |      1 |      1 |      1 |00:00:00.01 |     934 |       |       |          |
|   2 |   VIEW                   | VM_NWVW_1   |      1 |   1423 |  17484 |00:00:00.01 |     934 |       |       |          |
|   3 |    HASH GROUP BY         |             |      1 |   1423 |  17484 |00:00:00.01 |     934 |  2406K|  2406K| 1937K (0)|
|*  4 |     HASH JOIN SEMI       |             |      1 |   1423 |  17484 |00:00:00.01 |     934 |  2801K|  2801K| 2242K (0)|
|   5 |      INDEX FAST FULL SCAN| SYS_C008394 |      1 |  17347 |  20000 |00:00:00.01 |      55 |       |       |          |
|*  6 |      TABLE ACCESS FULL   | SALARIES    |      1 |    137K|    144K|00:00:00.01 |     879 |       |       |          |
-----------------------------------------------------------------------------------------------------------------------------
Predicate Information (identified by operation id):
---------------------------------------------------
 
   4 - access("E"."EMP_NO"="EMP_NO")
   6 - filter("SALARY">50000)

-- 튜닝
SELECT COUNT(E.EMP_NO) AS CNT
FROM EMPLOYEES E
WHERE EXISTS (
    SELECT 1
    FROM SALARIES S
    WHERE S.EMP_NO = E.EMP_NO
        AND SALARY > 50000
    );
---------------------------------------------------------------------------------------------------------------------------
| Id  | Operation              | Name        | Starts | E-Rows | A-Rows |   A-Time   | Buffers |  OMem |  1Mem | Used-Mem |
---------------------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT       |             |      1 |        |      1 |00:00:00.03 |     934 |       |       |          |
|   1 |  SORT AGGREGATE        |             |      1 |      1 |      1 |00:00:00.03 |     934 |       |       |          |
|*  2 |   HASH JOIN SEMI       |             |      1 |   1423 |  17484 |00:00:00.03 |     934 |  2801K|  2801K| 1842K (0)|
|   3 |    INDEX FAST FULL SCAN| SYS_C008394 |      1 |  17347 |  20000 |00:00:00.01 |      55 |       |       |          |
|*  4 |    TABLE ACCESS FULL   | SALARIES    |      1 |    137K|    144K|00:00:00.01 |     879 |       |       |          |
---------------------------------------------------------------------------------------------------------------------------
-- 실행 계획 확인
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));