**free
ctl-opt main(FtpUsrMgr);

/copy ./common_h.rpgle

dcl-f LGNUSRS disk(*EXT) usage(*INPUT) extfile(FTPLGNUSRS) rename(LGNUSRS:USERS) keyed usropn;

dcl-ds dsAppSpec_t qualified template;
  nameFmt       int(10);
  curWrkDir     int(10);
  lstFmt        int(10);
  ctlCnnSM      int(10);
  dataCnnSM     int(10);
  ctlCnnCiph    int(5);
  dataCnnCiph   int(5);
end-ds;

dcl-proc FtpUsrMgr;
  dcl-pi *N;
    pAppId              int(10);
    pSrcUsr             char(10);   
    pSrcUsrLen          int(10);
    pAuthStr            char(255);
    pAuthStrLen         int(10);
    pAuthCCSID          int(10);
    pClntIP             char(255);
    pClntIPLen          int(10);
    pAlwLgn             int(10);
    pTgtUsr             char(10);
    pTgtPwd             char(255);
    pTgtPwdLen          int(10);
    pTgtCCSID           int(10);
    pCurLib             char(10);
    pHomeDir            char(255);
    pHomeDirLen         int(10);
    pHDCCSID            int(10);
    pAppSpec            likeds(dsAppSpec_t);
    pAppSpecLen         int(10);
  end-pi;

  dcl-s usrK char(11) inz(*blanks);
  open(E) LGNUSRS;
  if not %error;
    usrK = pSrcUsr;
    setll(E) usrK LGNUSRS;
    read(E) LGNUSRS; 
      pAlwLgn = ALWLGN;

      select;
      when ALWLGN = 0;
        pAlwLgn = 0;
      when ALWLGN =  1;
        if AUTHSTR <> *blanks and pAuthStr <> AUTHSTR;
          pAlwLgn = 0;
        endif;
      when ALWLGN =  2;
      when ALWLGN =  3;
        pAlwLgn = ALWLGN;
      other;
        pAlwLgn = DFT_LGN_ALW;
      endsl; 

      if pAlwLgn <> 0 and CLNTIP <> *blanks and pClntIP <> CLNTIP;
        pAlwLgn = 0;
      endif;                                       

      pTgtUsr = TGTUSR;
      pAuthStrLen = %len(pTgtUsr);
      pAuthCCSID = 0;
      pTgtPwd = TGTPWD;
      pTgtPwdLen = %len(pTgtPwd);
      pTgtCCSID = 0;
      pCurLib = CURLIB;
      pHomeDir = HOMEDIR; 
      pHomeDirLen = %len(pHomeDir); 
      pHDCCSID = 0;

      pAppSpec.nameFmt = NAMEFMT; 
      pAppSpec.curWrkDir = CURWRKDIR; 
      pAppSpec.lstFmt = LISTFMT; 
      pAppSpec.dataCnnSM = DTACNNSM; 
      pAppSpec.dataCnnCiph = DTACNNCIPH; 
      
  endif;
  close(E) LGNUSRS;

end-proc;





