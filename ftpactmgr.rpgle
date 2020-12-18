**free
ctl-opt dftactgrp(*no);
ctl-opt main(FtpActMgr);

/copy ./common_h.rpgle

dcl-f OPPERM disk(*EXT) usage(*INPUT) extfile(FTPOPPERM) 
  rename(OPPERM:OPPERMR) keyed usropn;

dcl-f OPAUD disk(*EXT) usage(*INPUT:*OUTPUT) extfile(FTPOPAUD) 
   keyed usropn qualified;

dcl-s WILDCARD ucs2(1) inz(%ucs2('*'));

dcl-ds dsOpPermK likerec(OPPERMR : *key);
dcl-ds dsOpAud likerec(OPAUD.OPAUD:*output);

dcl-pr cmdexc extpgm('QCMDEXC');
  cmd         char(512) Options(*VarSize) const;
  cmdlen      packed(15:5) const;
  cmdDbcs     char(3) Options(*NOPASS) const;
end-pr;

dcl-pr alcLck ind;
  obj       char(21) const;
  type      char(8)  const;
  waitS     int(10)  const; 
end-pr;

dcl-pr dlcLck ind;
  obj       char(21) const;
  type      char(8)  const;
end-pr;

dcl-pr doOpInfo;
  dcl-parm pOpId                int(10) value;
  dcl-parm pOpInfo              char(255);
  dcl-parm pOpInfoLen           int(10) value;
  dcl-parm pAllow               int(10);        //output
end-pr;

dcl-pr matched ind;   // return value
  pOpInfo         char(255);
  pOpInfoLen      int(10) value;
end-pr;

dcl-pr doOpAud;
  dcl-parm pUser                char(10);
  dcl-parm pOpId                int(10) value;
  dcl-parm pOpInfo              char(255);
  dcl-parm pRmtIp               char(255);
  dcl-parm pAllow               int(10);
end-pr;

dcl-proc FtpActMgr;
  dcl-pi *N;
    pAppId              int(10);
    pOpId               int(10);
    pUser               char(10); 
    pRmtIp              char(255);
    pRmtIpLen           int(10);
    pOpInfo             char(255);
    pOpInfoLen          int(10);
    pAllow              int(10); 
  end-pi;

  pAllow = DFT_REQ_ALW;

  open(E) OPPERM;
  if %error;
    return;
  endif;

  dsOpPermK.USR = pUser;
  dsOpPermK.OPID = pOpId;
  setll(E) %kds(dsOpPermK) OPPERM;
  if %error;
    close(E) OPPERM;
    return;
  endif;
  read(E) OPPERM;
  if %error;
    close(E) OPPERM;
    return;
  endif;

  select;
    when pOpId = 0; // New connection for client.
    when pOpId = 1; // MKD, XMDK
      doOpInfo(pOpId:pOpInfo:pOpInfoLen:pAllow);
    when pOpId = 2; // RMD, XRMD
    when pOpId = 3; // CWD, CDUP, XCWD, XCUP 
    when pOpId = 4; // LIST, NLIST
      doOpInfo(pOpId:pOpInfo:pOpInfoLen:pAllow);
    when pOpId = 5; // DELE
      doOpInfo(pOpId:pOpInfo:pOpInfoLen:pAllow);
    when pOpId = 6; // RETR
      doOpInfo(pOpId:pOpInfo:pOpInfoLen:pAllow);
    when pOpId = 7; // APPE, STOR, STOU 
      doOpInfo(pOpId:pOpInfo:pOpInfoLen:pAllow); 
    when pOpId = 8; // RNFR, RNTO
      doOpInfo(pOpId:pOpInfo:pOpInfoLen:pAllow);
    when pOpId = 9; // RCMD, ADDm, ADDV, CRTL, CRTP, CRTS, DLTF, DLTL
    other;
  endsl;

  if pAllow > 0;
    doOpAud(pUser:pOpId:pOpInfo:pRmtIp:pAllow);
  endif;

  close(E) OPPERM;

end-proc;

dcl-proc doOpInfo;
  dcl-pi *N;
    pOpId               int(10) value;
    pOpInfo             char(255);
    pOpInfoLen          int(10) value;
    pAllow              int(10);
  end-pi;

  if ALLOWED = -1 or ALLOWED = 0; // check deny detail
    if OPINFO = *blanks; // deny all
      pAllow = ALLOWED;
    elseif matched(pOpInfo:pOpInfoLen); // deny specific
      pAllow = ALLOWED;
    else; // allow others
      pAllow = DFT_REQ_ALW;
    endif;
  else; // check allow detail
    if OPINFO = *blanks; // allow all
      pAllow = ALLOWED;
    elseif matched(pOpInfo:pOpInfoLen); // allow specific
      pAllow = ALLOWED;
    else; // deny others
      pAllow = DFT_REQ_DISALW;
    endif;
  endif; 

end-proc;

dcl-proc matched;
  dcl-pi *N ind;
    pOpInfo         char(255);
    pOpInfoLen      int(10) value;
  end-pi;

  dcl-s len int(10) inz(0);
  
  len = %len(%trim(OPINFO));
  if len = pOpInfoLen;
    if OPINFO = pOpInfo;
      return *on;
    else;
      return *off;
    endif;
  elseif len > pOpInfoLen; 
    return *off;
  elseif %subst(OPINFO : len : 1) = %char(WILDCARD); // end with wildcard?
    if %subst(OPINFO : 1: len-1) = pOpInfo;
      return *on;
    else;
      return *off;
    endif;
  endif;

end-proc;


dcl-proc doOpAud;
  dcl-pi *N;
    dcl-parm pUser                char(10);
    dcl-parm pOpId                int(10) value;
    dcl-parm pOpInfo              char(255);
    dcl-parm pRmtIp               char(255);
    dcl-parm pAllow               int(10);
  end-pi;

  alcLck(FTPOPAUD:'*SHRUPD':30);

  open(E) OPAUD;

  if not %error;
    dsOpAud.DATETIME = %timestamp();
    dsOpAud.USR = pUser;
    dsOpAud.OPID = pOpId;
    dsOpAud.OPINFO = pOpInfo;
    dsOpAud.RMTIP = pRmtIp;
    dsOpAud.ALLOWED = pAllow;
    write(E) OPAUD.OPAUD dsOpAud;
  endif;

  close(E) OPAUD;

  dlcLck(FTPOPAUD:'*SHRUPD');

end-proc;

dcl-proc alcLck;
  dcl-pi *N ind;
    obj       char(21) const;
    type      char(8)  const;
    waitS     int(10)  const;   
  end-pi;

  dcl-s rc ind inz(*ON);
  dcl-s cmd char(512) inz(*blanks);

  cmd  =  'ALCOBJ OBJ((' + obj + ' *FILE '
        + %trim(type) + ' OPAUD)) WAIT(' + %char(waitS) + ') SCOPE(*JOB)'; 

  monitor;
    cmdexc(%trim(cmd) : %len(%trim(cmd)));
  on-error;
    rc = *OFF;
  endmon;

  return rc;

end-proc;

dcl-proc dlcLck;
  dcl-pi *N ind;
    obj       char(21) const; 
    type      char(8)  const;
  end-pi;

  dcl-s rc ind inz(*ON);
  dcl-s cmd char(512) inz(*blanks);

  cmd  =  'DLCOBJ OBJ((' + obj
        + ' *FILE ' + %trim(type) + ' *FIRST)) SCOPE(*JOB)';

  monitor;
    cmdexc(%trim(cmd) : %len(%trim(cmd)));
  on-error;
    rc = *OFF;
  endmon;

  return rc;

end-proc;