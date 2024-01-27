select d.dname as department
,      e.job   as job
,      e.ename as employee
from   emp e
       right outer join
       dept d
       using (deptno)
order  by department, job;


select d.dname as department
,      e.job   as job
,      e.ename as employee
from   emp e
       PARTITION BY (JOB)
       right outer join
       dept d
       using (deptno)
order  by department, job;

--
create table emp
    (
    empno      NUMBER(4)    primary key,
    ename      VARCHAR2(8)  not null   ,
    init       VARCHAR2(5)  not null   ,
    job        VARCHAR2(8)             ,
    mgr        NUMBER(4)               ,
    bdate      DATE         not null   ,
    msal       NUMBER(6,2)  not null   ,
    comm       NUMBER(6,2)             ,
   deptno     NUMBER(2)    default 10
   ) ;
--
insert into emp values(7001,'SMITH','N',  'TRAINER', 7902,date '1975-12-17',  1800 , NULL, 20);
insert into emp values(7002,'ALLEN','JAM','SALESREP',7006,date '1971-05-20',  1600, 300,   30);
insert into emp values(7003,'WARD', 'TF' ,'SALESREP',7006,date '1972-03-02',  1250, 500,   10);
 insert into emp values(7004,'JACK', 'JM', 'MANAGER', 7009,date '1977-04-02',  2975, NULL,  20);
 insert into emp values(7005,'BROWN','P',  'SALESREP',7006,date '1976-09-28',  1250, 1400,  30);
 insert into emp values(7006,'BLAKE','R',  'MANAGER', 7009,date '1973-11-01',  2850, NULL,  10);
 insert into emp values(7007,'CLARK','AB', 'MANAGER', 7009,date '1975-06-09',  2450, NULL,  10);
 insert into emp values(7008,'SCOTT','DEF','TRAINER', 7004,date '1979-11-26',  3000, NULL,  20);
 insert into emp values(7009,'KING', 'CC', 'DIRECTOR',NULL,date '1972-10-17',  5000, NULL,  10);
 insert into emp values(7010,'BREAD','JJ', 'SALESREP',7006,date '1978-09-28',  1500, 0,     30);
 insert into emp values(7011,'ADAMS','AA', 'TRAINER', 7008,date '1976-12-30',  1100, NULL,  20);
 insert into emp values(7012,'JONES','R',  'ADMIN',   7006,date '1979-10-03',  8000, NULL,  30);
insert into emp values(7902,'FORD', 'MG', 'TRAINER', 7004,date '1979-02-13',  3000, NULL,  20);
insert into emp values(7934,'MARY', 'ABC','ADMIN',   7007,date '1972-01-23',  1300, NULL,  10);
--
commit;
--
create table departments
    (
      deptno    NUMBER(2)     primary key,
      dname     VARCHAR2(10)  not null unique check (dname = upper(dname)),
      location  VARCHAR2(8)   not null        check (location = upper(location)),
      mgr       NUMBER(4)
      ) ;
--
insert into departments values (10,'ACCOUNTING','NEW YORK',7007);
insert into departments values (20,'TRAINING',  'DALLAS',  7004);
insert into departments values (30,'SALES',     'CHICAGO', 7006);
insert into departments values (40,'HR',        'BOSTON',  7009);
--
commit;      
--
select d.dname as department
    ,      e.job   as job
    ,      e.ename as employee
    from   emp e
           PARTITION BY (JOB)
           right outer join
           departments d
           using (deptno)
    order  by department, job;
--
select d.dname as department
    ,      e.job   as job
    ,      e.ename as employee
    from   emp e
           right outer join
           departments d
           using (deptno)
    order  by department, job;    