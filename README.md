# iFTPMonitor
Based on IBM i (AS400) server exit point QIBM_QTMX_SVR_LOGON and QIBM_QTMF_CLIENT_REQ, you can easily
  - manage user logon settings
  - authorize data accesses for specific users
  - generate audit log for all files accessed per user
with customizing configuration files. 


## Configruation
```sh
#### Create logon user table ###################################
> CREATE TABLE IFTPMON.LGNUSRS (
  SRCUSR CHAR (11) CCSID 37 NOT NULL WITH DEFAULT PRIMARY KEY,                                           
  AUTHSTR CHAR (256) CCSID 1208 NOT NULL WITH DEFAULT, 
  CLNTIP CHAR (256) CCSID 37 NOT NULL WITH DEFAULT, 
  ALWLGN INT NOT NULL WITH DEFAULT,  
  TGTUSR CHAR (11) CCSID 37 NOT NULL WITH DEFAULT,  
  TGTPWD CHAR (256) CCSID 1208 NOT NULL WITH DEFAULT, 
  CURLIB CHAR (11) CCSID 37 NOT NULL WITH DEFAULT, 
  HOMEDIR CHAR (256) CCSID 1208 NOT NULL WITH DEFAULT,  
  NAMEFMT INT NOT NULL WITH DEFAULT, 
  CURWRKDIR INT NOT NULL WITH DEFAULT, 
  LISTFMT INT NOT NULL WITH DEFAULT, 
  DTACNNSM SMALLINT NOT NULL WITH DEFAULT, 
  DTACNNCIPH SMALLINT NOT NULL WITH DEFAULT   )                                                              

#### Create user permisson table ###############################
> CREATE TABLE IFTPMON.OPPERM (
  USR CHAR(11) CCSID 37 NOT NULL WITH DEFAULT,
  OPID INT NOT NULL WITH DEFAULT,
  OPINFO CHAR(256) CCSID 1208 NOT NULL WITH DEFAULT,
  ALLOWED INT NOT NULL WITH DEFAULT )     

> ALTER TABLE IFTPMON.OPPERM 
  ADD CONSTRAINT PK_FK
  PRIMARY KEY(USR, OPID)

#### Create audit table ########################################
> CREATE TABLE IFTPMON.OPAUD (
  DATETIME TIMESTAMP NOT NULL WITH DEFAULT PRIMARY KEY, 
  USR CHAR(11) CCSID 37 NOT NULL WITH DEFAULT,
  OPID INT NOT NULL WITH DEFAULT,
  OPINFO CHAR(256) CCSID 1208 NOT NULL WITH DEFAULT,
  RMTIP CHAR(256) CCSID 37 NOT NULL WITH DEFAULT,
  ALLOWED INT NOT NULL WITH DEFAULT ) 

#### Set up table authorities ##################################
> CHGOBJOWN OBJ(IFTPMON/LGNUSRS) OBJTYPE(*FILE) NEWOWN(QTCP)
> CHGOBJOWN OBJ(IFTPMON/OPPERM) OBJTYPE(*FILE) NEWOWN(QTCP)
> CHGOBJOWN OBJ(IFTPMON/OPAUD) OBJTYPE(*FILE) NEWOWN(QTCP)
> RVKOBJAUT OBJ(IFTPMON/LGNUSRS) OBJTYPE(*FILE) USER(*PUBLIC) AUT(*ALL) 
> RVKOBJAUT OBJ(IFTPMON/OPPERM) OBJTYPE(*FILE) USER(*PUBLIC) AUT(*ALL) 
> RVKOBJAUT OBJ(IFTPMON/OPAUD) OBJTYPE(*FILE) USER(*PUBLIC) AUT(*ALL) 
```
### Installation
```sh
> CRTLIB LIB(IFTPMON) TEXT('FTP MONITOR')

> ADDLIBL LIBL(IFTPMON)

> QSYS/CRTBNDRPG PGM(IFTPMON/FTPUSRMGR) SRCSTMF('/IFTPMON/ftpusrmgr.rpgle') TGTCCSID(*JOB)

> QSYS/CRTBNDRPG PGM(IFTPMON/FTPUSRMGR) SRCSTMF('/IFTPMON/ftpusrmgr.rpgle') TGTCCSID(*JOB)                              

> WRKREGINF EXITPNT(QIBM_QTMF_SVR_LOGON) FORMAT(TCPL0300)

> WRKREGINF EXITPNT(QIBM_QTMF_CLIENT_REQ) FORMAT(VLRQ0100)

> ENDTCPSVR SERVER(*FTP) 
> STRTCPSVR SERVER(*FTP) 

```

## Usage

### Configure logon user control 

```sh
> INSERT INTO IFTPMON.LGNUSRS VALUES(
  'SRCUSR', 'src_pwd',                   
  '', 1,                           
  'TGTUSR', 'tgt_pwd',          
  'QUSRSYS', '/HOME/',        
  0, 0, 0,                         
  0, 0)   
```

### Configure request permisson control

```sh
> INSERT INTO IFTPMON.OPPERM  VALUES(
    'SRCUSR', 3,                     
    '/HOME/URDIR', 1)                  
```

### View audit log for files accessed

```sh
> SELECT * FROM IFTPMON.OPAUD
  WHERE USR='AUSR'                            
```
