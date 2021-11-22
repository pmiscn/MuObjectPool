//
//---------------------------------------------------------------
//我不清楚LZO的授权是什么
//
//                                                               
//    Copyright(C) Jopher Software Studio,2006-2013. All rights reserved   
//                                                               
//                                                               
//---------------------------------------------------------------
//
unit utils_lzo;

interface

uses
   {$IF CompilerVersion>=23.0}Winapi.Windows{$ELSE}Windows{$IFEND},
   {$IFDEF UNICODE}
   {$IF CompilerVersion>=23.0}System.AnsiStrings{$ELSE}AnsiStrings{$IFEND},
   {$ENDIF}
   {$IF CompilerVersion>=23.0}System.Classes{$ELSE}Classes{$IFEND},
   {$IF CompilerVersion>=23.0}System.Sysutils{$ELSE}Sysutils{$IFEND};

   function lzo_compressdestlen(in_len: integer): integer;
   function lzo_compress(in_p: PAnsiChar; in_len: integer; out_p: PAnsiChar): integer;
   function lzo_decompressdestlen(in_p: PAnsiChar): integer;
   function lzo_decompress(in_p: PAnsiChar; in_len: integer; out_p: PAnsiChar): Integer;
   function LzoCompress(Data: AnsiString): AnsiString;
   function LzoDecompress(Data: AnsiString): AnsiString;
   function LzoCompressToStream(Data: AnsiString; TargetStream: TMemoryStream): boolean; overload;
   function LzoCompressToStream(SourceStream: TMemoryStream; TargetStream: TMemoryStream): boolean; overload;
   function LzoDecompressFromStream(SourceStream: TMemoryStream; var TargetData: AnsiString): boolean; overload;
   function LzoDecompressFromStream(SourceStream: TMemoryStream; TargetStream: TMemoryStream): boolean; overload;

implementation

//uses qbcommon;

{$define USEASM}

const
  M2_MAX_LEN=8;
  M3_MAX_LEN=33;
  M4_MAX_LEN=9;
  M4_MARKER=16;
  M3_MARKER=M4_MARKER+16;
  M2_MARKER=M3_MARKER+32;
  M2_MAX_OFFSET=$0800;
  M3_MAX_OFFSET=$4000;
  M4_MAX_OFFSET=$C000;
  MAX_OFFSET=M4_MAX_OFFSET-1;
  M4_OFF_BITS=11;
  M4_MASK=7 shl M4_OFF_BITS;
  D_BITS=14;
  D_MASK=(1 shl D_BITS) - 1;
  D_HIGH=(D_MASK shr 1)+1;
  D_MUL_SHIFT=5;
  D_MUL=(1 shl D_MUL_SHIFT)+1;

function do_compress(in_p: PAnsiChar; in_len: Integer; out_p: PAnsiChar; out out_len: integer): integer;
{$ifdef USEASM}
asm
        push    eax
        mov     eax, 16
@@1759: add     esp, -4092
        push    eax
        dec     eax
        jnz     @@1759
        mov     eax, [ebp-4H]
        add     esp, -24
        push    ebx
        push    esi
        push    edi
        mov     [ebp-8H], ecx
        mov     [ebp-4H], edx
        mov     ebx, eax
        mov     eax, [ebp-4H]
        add     eax, ebx
        mov     [ebp-0CH], eax
        mov     eax, [ebp-0CH]
        sub     eax, 9
        mov     [ebp-10H], eax
        mov     [ebp-14H], ebx
        add     ebx, 4
        mov     eax, [ebp-8H]
        mov     [ebp-18H], eax
        lea     eax, [ebp-1001CH]
        xor     ecx, ecx
        mov     edx, 65536
        call    System.@FillChar
        jmp     @@1760
        nop;nop;nop;nop;nop;nop;nop;nop;nop;nop;nop
@@1760: movzx   eax, byte ptr [ebx+3]
        movzx   edx, byte ptr [ebx+2]
        shl     eax, 6
        movzx   ecx, byte ptr [ebx+1]
        xor     eax, edx
        movzx   edx, byte ptr [ebx]
        shl     eax, 5
        xor     eax, ecx
        shl     eax, 5
        xor     eax, edx
        mov     edx, eax
        shl     eax, 5
        add     eax, edx
        shr     eax, 5
        and     eax, 3FFFH
        mov     edx,[ebp+eax*4-1001CH]
        test    edx, edx
        jnz     @@1762
@@1761: mov     [ebp+eax*4-1001CH], ebx
        inc     ebx
        cmp     ebx, [ebp-10H]
        jc      @@1760
        jmp     @@1788
        nop;nop;nop;nop;nop;nop
@@1762: mov     esi, ebx
        mov     edi, edx
        sub     esi, edx
        cmp     esi, 49151
        jg      @@1761
        cmp     esi, 2048
        jle     @@1763
        mov     cl, [ebx+3H]
        cmp     cl, [edi+3H]
        jz      @@1763
        and     eax, 7FFH
        xor     eax, 201FH
        mov     edx, [ebp+eax*4-1001CH]
        test    edx, edx
        mov     edi, edx
        mov     esi, ebx
        jz      @@1761
        sub     esi, edi
        cmp     esi, 49151
        jg      @@1761
        cmp     esi, 2048
        jle     @@1763
        cmp     cl, [edi+3H]
        jnz     @@1761
@@1763: mov     edx, [edi]
        cmp     dx, word ptr [ebx]
        jnz     @@1761
        shr     edx,16
        cmp     dl, [ebx+2H]
        jnz     @@1761
        mov     [ebp+eax*4-1001CH], ebx
        mov     eax, ebx
        sub     eax, [ebp-14H]
        je      @@1768
        cmp     eax, 3
        jg      @@1764
        mov     ecx, [ebp-8H]
        add     [ebp-8H], eax
        mov     edx, [ebp-14H]
        add     [ebp-14H], eax
        mov     edx, [edx]
        or      [ecx-2], al
        mov     [ecx], edx
        jmp     @@1768

@@1764: cmp     eax, 18
        jg      @@1765
        mov     ecx, [ebp-8H]
        lea     eax, eax-3
        mov     [ecx], al
        mov     edx, [ebp-14H]
        inc     ecx
        push    ebx
        mov     ebx,[edx]
        mov     [ecx],ebx
        dec     eax
        lea     edx,edx+4
        lea     ecx,ecx+4
        jz      @@0
@@1:    mov     bl,[edx]
        mov     [ecx],bl
        dec     eax
        lea     edx,edx+1
        lea     ecx,ecx+1
        jnz     @@1
@@0:    pop     ebx
        mov     [ebp-8H], ecx
        mov     [ebp-14H], edx
        jmp     @@1768

@@1765: mov     edx, eax
        sub     edx, 18
        mov     [ebp-1CH], edx
        mov     edx, [ebp-8H]
        mov     byte ptr [edx], 0
        inc     dword ptr [ebp-8H]
        cmp     dword ptr [ebp-1CH], 255
        jle     @@1767
@@1766: sub     dword ptr [ebp-1CH], 255
        mov     edx, [ebp-8H]
        mov     byte ptr [edx], 0
        inc     dword ptr [ebp-8H]
        cmp     dword ptr [ebp-1CH], 255
        jg      @@1766
@@1767: mov     dl, [ebp-1CH]
        mov     ecx, [ebp-8H]
        mov     [ecx], dl
        inc     dword ptr [ebp-8H]
        mov     edx, [ebp-8H]
        mov     ecx, [ebp-14H]
        xchg    ecx, eax
        call    move
        mov     eax, ebx
        sub     eax, [ebp-14H]
        add     [ebp-8H], eax
        add     [ebp-14H], eax

@@1768: mov     eax,[edi+3H]
        mov     ecx,[ebx+3H]
        cmp     al,cl
        jne     @@1784
        cmp     ah,ch
        jne     @@1783
        shr     eax,16
        shr     ecx,16
        cmp     al,cl
        jne     @@1782
        cmp     ah,ch
        jne     @@1781
        mov     ax,[edi+7H]
        mov     cx,[ebx+7H]
        cmp     al,cl
        jne     @@1780
        cmp     ah,ch
        jne     @@1779
        add     ebx,9
        mov     eax, [ebp-0CH]
        add     edi,9
        cmp     eax, ebx
        jbe     @@1771
        mov     dl, [edi]
        cmp     dl, [ebx]
        jnz     @@1771
@@1769: inc     ebx
        inc     edi
        cmp     eax, ebx
        jbe     @@1771
        mov     dl, [edi]
        cmp     dl, [ebx]
        jz      @@1769
@@1771: mov     eax, ebx
        sub     eax, [ebp-14H]
        cmp     esi, 16384
        jg      @@1773
        dec     esi
        cmp     eax, 33
        jg      @@1772
{$ifdef CONDITIONALEXPRESSIONS}
        lea     esi,esi*4
{$else} shl     esi,2      {$endif}
        sub     eax, 2
        mov     edx, [ebp-8H]
        or      eax, 20H
        mov     word ptr [edx+1], si
        mov     [edx], al
        add     edx, 3
        mov     [ebp-14H], ebx
        cmp     ebx, [ebp-10H]
        mov     [ebp-8H],edx
        jc      @@1760
        jmp     @@1788

@@1772: sub     eax, 33
        mov     edx, [ebp-8H]
        mov     byte ptr [edx], 32
        jmp     @@1775

@@1773: sub     esi, 16384
        cmp     eax, 9
        jg      @@1774
        mov     edx, esi
        and     edx, 4000H
        shr     edx, 11
        or      dl, 10H
        sub     al, 2
        or      dl, al
        mov     eax, [ebp-8H]
        mov     [eax], dl
        inc     dword ptr [ebp-8H]
        jmp     @@1778

@@1774: sub     eax, 9
        mov     edx, esi
        and     edx, 4000H
        shr     edx, 11
        or      dl, 10H
        mov     ecx, [ebp-8H]
        mov     [ecx], dl
@@1775: inc     dword ptr [ebp-8H]
        cmp     eax, 255
        jle     @@1777
@@1776: sub     eax, 255
        mov     edx, [ebp-8H]
        mov     byte ptr [edx], 0
        inc     dword ptr [ebp-8H]
        cmp     eax, 255
        jg      @@1776
@@1777: mov     edx, [ebp-8H]
        mov     [edx], al
        inc     dword ptr [ebp-8H]
@@1778:
{$ifdef CONDITIONALEXPRESSIONS}
        lea     esi,esi*4
{$else} shl     esi,2      {$endif}
        mov     eax, [ebp-8H]
        add     dword ptr [ebp-8H], 2
        mov     word ptr [eax], si
        mov     [ebp-14H], ebx
        cmp     ebx, [ebp-10H]
        jc      @@1760
        jmp     @@1788
@@1779: inc     ebx
@@1780: inc     ebx
@@1781: inc     ebx
@@1782: inc     ebx
@@1783: inc     ebx
@@1784: add     ebx, 3
@@1785: cmp     esi, 2048
        jg      @@1786
        dec     esi
        mov     edx, esi
        shr     esi, 3
        mov     ecx, [ebp-14H]
        and     edx, 07H
        lea     eax, ebx-1
        shl     esi, 8
        sub     eax, ecx
{$ifdef CONDITIONALEXPRESSIONS}
        lea     edx,edx*4
{$else} shl     edx,2      {$endif}
        shl     eax, 5
        or      eax, edx
        mov     edx, [ebp-8H]
        or      eax, esi
        add     dword ptr [ebp-8H], 2
        mov     [edx], ax
        mov     [ebp-14H], ebx
        cmp     ebx, [ebp-10H]
        jc      @@1760
        jmp     @@1788

@@1786: cmp     esi, 16384
        jg      @@1787
        lea     eax, ebx-2
        dec     esi
        sub     eax, [ebp-14H]
        shl     esi, 10
        or      eax, 20H
        mov     edx, [ebp-8H]
        or      eax, esi
        add     dword ptr [ebp-8H], 3
        mov     [edx], eax
        mov     [ebp-14H], ebx
        cmp     ebx, [ebp-10H]
        jc      @@1760
        jmp     @@1788
@@1787: sub     esi, 16384
        lea     eax, ebx-2
        mov     edx, esi
        sub     eax, [ebp-14H]
        and     edx, 4000H
        or      eax, 10H
        shr     edx, 11
        or      eax, edx
        mov     edx, [ebp-8H]
        mov     [edx], al
        inc     dword ptr [ebp-8H]
{$ifdef CONDITIONALEXPRESSIONS}
        lea     esi,esi*4
{$else} shl     esi,2      {$endif}
        mov     eax, [ebp-8H]
        mov     word ptr [eax], si
        add     dword ptr [ebp-8H], 2
        mov     [ebp-14H], ebx
        cmp     ebx, [ebp-10H]
        jc      @@1760
@@1788: mov     eax, [ebp-8H]
        sub     eax, [ebp-18H]
        mov     edx, [ebp+8H]
        mov     [edx], eax
        mov     eax, [ebp-0CH]
        sub     eax, [ebp-14H]
        pop     edi
        pop     esi
        pop     ebx
        mov     esp, ebp
end;
{$else}
var in_end, ip_end, ii, end_p, m_pos, out_beg: PAnsiChar;
    m_off, m_len, dindex, t, tt: Integer;
{$ifdef USEOFFSET}
    dict: array[0..D_MASK] of integer;
    ip_beg: PAnsiChar;
{$else}
    dict: array[0..D_MASK] of PAnsiChar;
{$endif}
label lit, try_match, match, same4, m3_m4_len, m3_m4_offset, m1;
begin
  in_end := in_p+in_len;
  ip_end := in_end-9;
{$ifdef USEOFFSET}
  ip_beg := in_p;
{$endif}
  ii := in_p;
  inc(in_p,4);
  out_beg := out_p;
  FillChar(dict,sizeof(dict),0);
  repeat
    dindex := ((D_MUL * ((((((ord(in_p[3]) shl 6) xor ord(in_p[2])) shl 5)
      xor ord(in_p[1])) shl 5) xor ord(in_p[0]))) shr D_MUL_SHIFT) and D_MASK;
{$ifdef USEOFFSET}
    if dict[dindex]=0 then
    begin
lit:  dict[dindex] := in_p-ip_beg;
{$else}
    if dict[dindex]=nil then
       begin
lit:     dict[dindex] := in_p;
{$endif}
         inc(in_p);
         if in_p<ip_end then
           continue
         else
           break;
       end
    else
{$ifdef USEOFFSET}
      m_pos := @ip_beg[dict[dindex]]; {$else}
      m_pos := dict[dindex];
{$endif}
    m_off := in_p-m_pos;
    if {$ifdef WT}(m_off<3)or{$endif} (m_off>MAX_OFFSET) then
      goto lit else
      if (m_off<=M2_MAX_OFFSET) or (m_pos[3]=in_p[3]) then
        goto try_match;
    dindex := (dindex and (D_MASK and $7ff)) xor (D_HIGH or $1f);
{$ifdef USEOFFSET}
    if dict[dindex]=0 then
      goto lit else
      m_pos := @ip_beg[dict[dindex]];
{$else}
    if dict[dindex]=nil then
      goto lit else
      m_pos := dict[dindex];
{$endif}
    m_off := in_p-m_pos;
    if {$ifdef WT}(m_off<3)or{$endif} (m_off>MAX_OFFSET) then
      goto lit else
    if (m_off<=M2_MAX_OFFSET) or (m_pos[3]=in_p[3]) then
       goto try_match else
       goto lit;
try_match:
    if (pWord(m_pos)^<>pWord(in_p)^) or (m_pos[2]<>in_p[2]) then
      goto lit;
match:
{$ifdef USEOFFSET}
    dict[dindex] := in_p-ip_beg; {$else}
    dict[dindex] := in_p;
{$endif}
    t := in_p-ii;
    if t<>0 then
       begin
         if t<=3 then
            begin
              PByte(out_p-2)^ := PByte(out_p-2)^ or t;
              pInteger(out_p)^ := pInteger(ii)^;
              inc(out_p,t);
              inc(ii,t);
            end
         else
         if t<=18 then
            begin
              out_p^ := ansichar(t-3);
              inc(out_p);
              movechars(ii,out_p,t);
              inc(out_p,in_p-ii);
              inc(ii,in_p-ii);
            end
         else
            begin
              tt := t-18;
              out_p^ := #0; inc(out_p);
              while tt>255 do
                 begin
                   dec(tt,255);
                   out_p^ := #0;
                   inc(out_p);
                 end;
              out_p^ := ansichar(tt);
              inc(out_p);
              system.move(ii^,out_p^,t);
              inc(out_p,in_p-ii);
              inc(ii,in_p-ii);
            end;
       end;
    {$ifdef WT}
    t := m_off;
    {$endif}
    if (m_pos[3]=in_p[3]) {$ifdef WT}and (t>3){$endif} then
      if (m_pos[4]=in_p[4]) {$ifdef WT}and (t>4){$endif} then
        if (m_pos[5]=in_p[5]) {$ifdef WT}and (t>5){$endif} then
          if (m_pos[6]=in_p[6]) {$ifdef WT}and (t>6){$endif} then
same4:      if (m_pos[7]=in_p[7]) {$ifdef WT}and (t>7){$endif} then
              if (m_pos[8]=in_p[8]) {$ifdef WT}and (t>8){$endif} then
              begin
                inc(in_p,9);
                end_p := in_end;
                inc(m_pos,M2_MAX_LEN+1);
                {$ifdef WT}dec(t,9);{$endif}
                while (in_p<end_p) and (m_pos^=in_p^) {$ifdef WT}and (t>0){$endif} do
                   begin
                     inc(in_p);
                     inc(m_pos);
                     {$ifdef WT}dec(t);{$endif}
                   end;
                m_len := in_p-ii;
                if m_off<=M3_MAX_OFFSET then
                   begin
                     dec(m_off);
                     if m_len<=33 then
                        begin
                          out_p^ := ansichar(integer(M3_MARKER or (m_len-2)));
                          inc(out_p);
                          pWord(out_p)^ := m_off shl 2;
                          inc(out_p,2);
                          ii := in_p;
                          if in_p<ip_end then
                             continue
                          else
                             break;
                        end
                     else
                        begin
                          dec(m_len,33);
                          out_p^ := ansichar(M3_MARKER);
                          goto m3_m4_len;
                        end;
                   end
                else
                   begin
                     dec(m_off,M3_MAX_OFFSET);
                     if (m_len<=M4_MAX_LEN) then
                        begin
                          out_p^ := ansichar(integer(M4_MARKER or
                            ((m_off and M3_MAX_OFFSET)shr M4_OFF_BITS) or (m_len-2)));
                          inc(out_p);
                        end
                     else
                        begin
                          dec(m_len,M4_MAX_LEN);
                          out_p^ := ansichar(integer(M4_MARKER or ((m_off and M3_MAX_OFFSET)shr M4_OFF_BITS)));
m3_m4_len:                inc(out_p);
                          while (m_len>255) do
                             begin
                               dec(m_len,255);
                               out_p^ := #0;
                               inc(out_p);
                             end;
                          out_p^ := ansichar(m_len);
                          inc(out_p);
                        end;
                   end;
                pWord(out_p)^ := m_off shl 2;
                inc(out_p,2);
                ii := in_p;
                if in_p<ip_end then
                   continue
                else
                   break;
              end else inc(in_p,8)
            else inc(in_p,7)
          else inc(in_p,6)
        else inc(in_p,5)
      else inc(in_p,4)
    else inc(in_p,3);
    if m_off<=M2_MAX_OFFSET then
       begin
         dec(m_off);
         pWord(out_p)^ := integer(((in_p-ii-1)shl 5) or ((m_off and 7)shl 2) or ((m_off shr 3) shl 8));
         inc(out_p,2);
         ii := in_p;
         if in_p<ip_end then
            continue
         else
            break;
       end
    else
    if m_off<=M3_MAX_OFFSET then
       begin
         dec(m_off);
         pInteger(out_p)^ := integer(M3_MARKER or (in_p-ii-2) or (m_off shl 10));
         inc(out_p,3);
         ii := in_p;
         if in_p<ip_end then
            continue
         else
            break;
       end
    else
       begin
         dec(m_off,M3_MAX_OFFSET);
         out_p^ := ansichar(integer(M4_MARKER or (in_p-ii-2) or ((m_off and M3_MAX_OFFSET)shr M4_OFF_BITS)));
m1:      inc(out_p);
         pWord(out_p)^ := m_off shl 2;
         inc(out_p,2);
         ii := in_p;
         if in_p<ip_end then
            continue
         else
            break;
       end;
  until false;
  out_len := out_p-out_beg;
  result := in_end-ii;
end;

{$endif USEASM}

function lzo_compressdestlen(in_len: integer): integer;
begin
  result := in_len+(in_Len shr 3)+(64+7);
end;

function lzo_compress(in_p: PAnsiChar; in_len: integer; out_p: PAnsiChar): integer;
var
   out_beg: PAnsiChar;
   t, tt: Integer;
label mov;
begin
  out_beg := out_p;
  if in_len>=$8000 then
     begin
       pWord(out_p)^ := $8000 or (in_len and $7fff);
       pWord(out_p+2)^ := in_len shr 15;
       inc(out_p,4);
     end
  else
     begin
       pWord(out_p)^ := in_len;
       if in_len=0 then
          begin
            result := 2;
            exit;
          end;
       inc(out_p,2);
     end;
  if in_len<=M2_MAX_LEN+5 then
     begin
       t := in_len;
       out_p^ := ansichar(t+17);
       goto mov;
     end
  else
     begin
       t:= do_compress(in_p, in_len, out_p, result);
       inc(out_p,result);
     end;
  if t>0 then
     begin
       if t<=3 then
         inc(out_p[-2],t)
       else
       if t<=18 then
          begin
            out_p^ := ansichar(t-3);
            inc(out_p);
          end
       else
          begin
            tt := t-18;
            out_p^ := #0;
            inc(out_p);
            while tt>255 do
               begin
                 dec(tt,255);
                 out_p^ := #0;
                 inc(out_p);
               end;
            out_p^ := ansichar(tt);
mov:        inc(out_p);
          end;
       system.move((in_p+in_len-t)^,out_p^,t);
       inc(out_p,t);
     end;
  result := out_p-out_beg;
end;

function lzo_decompressdestlen(in_p: PAnsiChar): integer;
begin
  result := pWord(in_p)^;
  inc(in_p,2);
  if result and $8000<>0 then
    result := (result and $7fff) or (integer(pWord(in_p)^) shl 15);
end;

function lzo_decompress(in_p: PAnsiChar; in_len: integer; out_p: PAnsiChar): Integer;
{$ifdef USEASM}
asm
        push    ebx
        push    esi
        push    edi
        push    ebp
        add     esp, -16
        mov     edi, ecx
        mov     [esp], edx
        mov     esi, eax
        mov     eax, [esp]
        add     eax, esi
        mov     [esp+8H], eax
        movzx   eax, word ptr [esi]
        test    eax,eax
        mov     [esp+4H], eax
        je      @@1829
        add     esi, 2
        test    byte ptr [esp+5H], 80H
        jz      @@1806
        mov     eax, [esp+4H]
        and     eax, 7FFFH
        movzx   edx, word ptr [esi]
        shl     edx, 15
        or      eax, edx
        mov     [esp+4H], eax
        add     esi, 2
@@1806: mov     eax, [esp+4H]
        add     eax, edi
        mov     [esp+0CH], eax
        movzx   ebx, byte ptr [esi]
        cmp     ebx, 17
        jle     @@1807
        sub     ebx, 17
        inc     esi
        cmp     ebx, 4
        jl      @@1826
@@s:    mov     al,[esi]
        mov     [edi],al
        dec     ebx
        lea     esi,esi+1
        lea     edi,edi+1
        jnz     @@s
        jmp     @@1812

        nop;nop
@@1807: cmp     esi, [esp+8H]
        jnc     @@1829
@@1808: movzx   ebx, byte ptr [esi]
        inc     esi
        cmp     ebx, 16
        jge     @@1813
        test    ebx, ebx
        jnz     @@1811
        cmp     byte ptr [esi], 0
        jnz     @@180a
@@1809: add     ebx, 255
        inc     esi
@@1810: cmp     byte ptr [esi], 0
        jz      @@1809
@@180a: movzx   eax, byte ptr [esi]
        add     eax,15
        add     ebx,eax
        inc     esi
@@1811: add     ebx,3
        mov     edx, edi
        mov     eax, esi
        mov     ecx, ebx
        call    move
        add     esi, ebx
        add     edi, ebx
@@1812: cmp     esi, [esp+8H]
        jnc     @@1829
        movzx   ebx, byte ptr [esi]
        inc     esi
@@1813: cmp     ebx, 64
        jl      @@1814
        lea     ebp, edi-1
        mov     eax, ebx
        shr     eax, 2
        and     eax, 07H
        sub     ebp, eax
        mov     al, [esi]
        inc     esi
        shl     eax, 3
        shr     ebx, 5
        sub     ebp, eax
        inc     ebx
        lea     eax, ebx+edi
        cmp     eax, [esp+0CH]
        jbe     @@1824
        mov     ebx, [esp+0CH]
        sub     ebx, edi
        jmp     @@1824

@@1814: cmp     ebx, 32
        jl      @@1818
        and     ebx, 1FH
        jnz     @@1817
        cmp     byte ptr [esi], 0
        jnz     @@181a
@@1815: add     ebx, 255
        inc     esi
@@1816: cmp     byte ptr [esi], 0
        jz      @@1815
@@181a: movzx   eax, byte ptr [esi]
        add     eax,31
        add     ebx,eax
        inc     esi
@@1817: lea     ebp, edi-1
        movzx   eax, word ptr [esi]
        shr     eax, 2
        sub     ebp, eax
        add     esi, 2
        jmp     @@1822

@@1818: cmp     ebx, 16
        jl      @@1822
        mov     eax, ebx
        and     eax, 08H
        shl     eax, 11
        lea     ebp,edi-16384
        sub     ebp, eax
        and     ebx, 07H
        jnz     @@1821
        cmp     byte ptr [esi], 0
        jnz     @@182a
@@1819: add     ebx, 255
        inc     esi
@@1820: cmp     byte ptr [esi], 0
        jz      @@1819
@@182a: movzx   eax, byte ptr [esi]
        add     eax, 7
        add     ebx, eax
        inc     esi
@@1821: movzx   eax, word ptr [esi]
        shr     eax, 2
        sub     ebp, eax
        add     esi, 2
@@1822: lea     eax, [ebx+edi+2]
        lea     ebx, ebx+2
        cmp     eax, [esp+0CH]
        jbe     @@1823
        mov     ebx, [esp+0CH]
        sub     ebx, edi
@@1823: cmp     ebx, 6
        mov     ecx, edi
        jl      @@1824
        sub     ecx, ebp
        cmp     ebx, ecx
        jg      @@1824
        mov     edx, edi
        mov     eax, ebp
        mov     ecx, ebx
        call    move
        add     edi, ebx
        jmp     @@1825
        nop;nop;nop
@@1824: mov     al,[ebp]
        mov     [edi],al
        dec     ebx
        lea     edi,edi+1
        jz      @@1825
        mov     al,[ebp+1]
        mov     [edi],al
        dec     ebx
        lea     ebp,ebp+2
        lea     edi,edi+1
        jnz     @@1824
@@1825: movzx   ecx, byte ptr [esi-2H]
        and     ecx, 3
        jz      @@1807
@@1826: dec     ecx
        mov     al,[esi]
        mov     [edi],al
        lea     esi,esi+1
        lea     edi,edi+1
        jz      @@1827
        dec     ecx
        mov     al,[esi]
        mov     [edi],al
        lea     esi,esi+1
        lea     edi,edi+1
        jz      @@1827
        mov     al,[esi]
        mov     [edi],al
        lea     esi,esi+1
        lea     edi,edi+1
@@1827: movzx   ebx, byte ptr [esi]
        lea     esi, esi+1
        cmp     esi, [esp+8H]
        jc      @@1813
@@1829: mov     eax, [esp+4H]
        add     esp, 16
        pop     ebp
        pop     edi
        pop     esi
        pop     ebx
end;
{$else}
var
   ip_end, m_pos, out_end: PAnsiChar;
   t: Integer;
label
   match_next, first_literal_run, match, match_done, copy_m, m1;
begin
  ip_end := in_p+in_len;
  result := pWord(in_p)^;
  if result=0 then
     exit;
  inc(in_p,2);
  if result and $8000<>0 then
     begin
       result := (result and $7fff) or (integer(pWord(in_p)^) shl 15);
       inc(in_p,2);
     end;
  out_end := out_p+result;
  t := ord(in_p[0]);
  if t>17 then
     begin
       dec(t,17);
       inc(in_p);
       if t<4 then
         goto match_next;
       movechars(in_p,out_p,t);
       inc(out_p,t);
       inc(in_p,t);
       goto first_literal_run;
     end;
  while in_p<ip_end do
     begin
       t := ord(in_p[0]);
       inc(in_p);
       if t>=16 then
         goto match
       else
          if t=0 then
             begin
               while in_p[0]=#0 do
                  begin
                    inc(t,255);
                    inc(in_p);
                  end;
               inc(t,15+ord(in_p[0]));
               inc(in_p);
             end;
       inc(t,3);
       system.Move(in_p^,out_p^,t);
       inc(in_p,t);
       inc(out_p,t);
first_literal_run:
       if in_p>=ip_end then
         break;
       t := ord(in_p[0]);
       inc(in_p);
       repeat
match:   if t>=M2_MARKER then
            begin
              m_pos := out_p-1-((t shr 2) and 7)-(ord(in_p[0])shl 3);
              inc(in_p);
              t := (t shr 5)+1;
              if out_p+t>out_end then
                t := out_end-out_p;
              goto copy_m;
            end
          else
            if t>=M3_MARKER then
               begin
                 t := t and 31;
                 if t=0 then
                    begin
                      while in_p[0]=#0 do
                         begin
                           inc(t,255);
                           inc(in_p);
                         end;
                      inc(t,31+ord(in_p[0]));
                      inc(in_p);
                    end;
                 m_pos := out_p-1-(pWord(in_p)^ shr 2);
                 inc(in_p,2);
               end
            else
               if t>=M4_MARKER then
                  begin
                    m_pos := out_p-((t and 8)shl M4_OFF_BITS)-M3_MAX_OFFSET;
m1:                 t := t and 7;
                    if t=0 then
                       begin
                         while in_p[0]=#0 do
                            begin
                              inc(t,255);
                              inc(in_p);
                            end;
                         inc(t,7+ord(in_p[0]));
                         inc(in_p);
                       end;
                    dec(m_pos,pWord(in_p)^ shr 2);
                    inc(in_p,2);
                  end;
         inc(t,2);
         if out_p+t>out_end then
           t := out_end-out_p;
         if (t>=6) and (out_p-m_pos>=t) then
           system.Move(m_pos^,out_p^,t)
         else
copy_m:    movechars(m_pos,out_p,t);
         inc(out_p,t);
match_done:
         t := ord(in_p[-2]) and 3;
         if t=0 then
            break;
match_next:
         out_p^ := in_p^;
         inc(out_p);
         inc(in_p);
         if t<>1 then
            begin
              out_p^ := in_p^;
              inc(out_p);
              inc(in_p);
              if t=3 then
                 begin
                   out_p^ := in_p^;
                   inc(out_p);
                   inc(in_p);
                 end;
            end;
         t := ord(in_p[0]);
         inc(in_p);
       until in_p>=ip_end;
     end;
end;

{$endif USEASM}

function LzoCompress(Data: AnsiString): AnsiString;
var
   DataLen, len, newlen: integer;
begin
   DataLen := length(Data);
   len:= lzo_compressdestlen(DataLen);
   SetString(result,nil,len);
   newlen := lzo_compress(PAnsiChar(Data),DataLen,PAnsiChar(result));
   if (newlen<>len) and (newlen>=0) then
      setlength(result,newlen);
end;

function LzoDecompress(Data: AnsiString): AnsiString;
var
   len, newlen: integer;
begin
   len:=lzo_decompressdestlen(Pointer(data));
   SetString(result,nil,len);
   newlen:=lzo_decompress(PAnsiChar(data),length(Data),PAnsiChar(result));
   if (newlen<>len) and (newlen>=0) then
      setlength(result,newlen);
end;

function LzoCompressToStream(Data: AnsiString; TargetStream: TMemoryStream): boolean;
var
   DataLen, len, newlen: integer;
begin
   try
      DataLen := length(Data);
      len:= lzo_compressdestlen(DataLen);
      TargetStream.SetSize(len);
      TargetStream.Position:=0;
      newlen := lzo_compress(PAnsiChar(Data),DataLen,TargetStream.Memory);
      if (newlen<>len) and (newlen>=0) then
         TargetStream.SetSize(newlen);
      result:=true;
   except
      result:=false;
   end;
end;

function LzoCompressToStream(SourceStream: TMemoryStream; TargetStream: TMemoryStream): boolean; overload;
var
   DataLen, len, newlen: integer;
begin
   try
      DataLen := SourceStream.Size;
      len:= lzo_compressdestlen(DataLen);
      TargetStream.SetSize(len);
      SourceStream.Position:=0;
      TargetStream.Position:=0;
      newlen := lzo_compress(SourceStream.Memory,DataLen,TargetStream.Memory);
      if (newlen<>len) and (newlen>=0) then
         TargetStream.SetSize(newlen);
      result:=true;
   except
      result:=false;
   end;
end;

function LzoDecompressFromStream(SourceStream: TMemoryStream; var TargetData: AnsiString): boolean; overload;
var
   len, newlen: integer;
begin
   try
      SourceStream.Position:=0;
      len:=lzo_decompressdestlen(SourceStream.Memory);
      SetString(TargetData,nil,len);
      newlen:=lzo_decompress(SourceStream.Memory,SourceStream.Size,PAnsiChar(TargetData));
      if (newlen<>len) and (newlen>=0) then
         setlength(TargetData,newlen);
      Result:=true;
   except
      result:=false;
   end;
end;

function LzoDecompressFromStream(SourceStream: TMemoryStream; TargetStream: TMemoryStream): boolean; overload;
var
   len, newlen: integer;
begin
   try
      SourceStream.Position:=0;
      len:=lzo_decompressdestlen(SourceStream.Memory);
      TargetStream.SetSize(len);
      TargetStream.Position:=0;
      newlen:=lzo_decompress(SourceStream.Memory,SourceStream.Size,TargetStream.Memory);
      if (newlen<>len) and (newlen>=0) then
         TargetStream.SetSize(newlen);
      Result:=true;
   except
      result:=false;
   end;
end;

end.

