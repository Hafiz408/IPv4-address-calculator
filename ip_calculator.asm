include "emu8086.inc"

org 100h    

;             Various procedures called to do the task
call input     
call printip
call binary
call network
call broadcast
call subn
call host 
call wild 
call pause
call credits
call endprog
           
input proc         
;-------------------------- Opening screen ----------------------------------

    GOTOXY 34, 10
    print "Hello "
    GOTOXY 23, 13
    printn "Welcome to IP calculator(IPv4)"
    mov cx, 5
;Used so that the welcome screen stays for few seconds
    space:
    printn ""
    loop space
    
    call clear_screen
    mov cx, 0


    GOTOXY 20, 0
    print "Input data "  
    GOTOXY 0, 2
;-----------------------taking IP address as input as 4 octet ---------------------------
    start:
    print "Enter octet: "
    call    scan_num
    printn ""
    
    mov ip[si], cl  
    inc si
    inc e           
    cmp e, 4
    jne start       
    
;----------------------- prefix mask and storing -------------------------- 
    printn ""
    print "Prefix: "
    
    mov cx, 2                
    mov si, 0

    prefixing:
    	mov ah, 1
        int 21h
        cmp al, 13              
        je calc
        mov mask[si],al
        inc si
        loop prefixing  
        
; converts and stores the prefix if it a 2 digit number
    calc:
    	cmp si, 1                
    	je line1
	
    				
    	mov dx, 0
    	mov cx, si
    	mov si,0
    	multiple:
    		mov al, mask[si]
    		sub al, 30h             
    		mov bl, g
    		mul bl
    		add dx, ax              
    		mov g,1
    		inc si
    		
		loop multiple
    
    		mov prefix, dl          
    		mov dx, 0
    		mov ax, 0
    
    		jmp print

; converts and stores the prefix if it a 1 digit number    
    line1:                 
    mov si, 0
    mov al, mask[si]
    mov prefix, al
    sub prefix, 30h 
ret
input endp
    
;--------------------------IP address printing----------------------------  
printip proc    
    GOTOXY 20, 8
    print "Output "
    printn ""
    
    mov cx,1 
    print:
    cmp cx,0
    jne r
    printn ""
    print "IP Address: "     
    mov cx, 3                 
    mov si, 0
    
    move:
    mov al, ip[si]
    mov ah, 0
    call print_num
    mov dl, '.'               
    mov ah, 2
    int 21h
    inc si
    loop move
    mov al, ip[si]
    mov ah, 0   
    dec cx
    call print_num 
    
    r:
    ret    
ret 
printip endp
	
;----------------------Binary calculation of IP ---------------------------- 
binary proc
    mov c, 7                      
    mov si, 0
    mov f, 4                      
    
    moving:
    mov ah, 0
    mov al, ip[si]                
    mov e, si
    mov bh, 0
    
    MOV bl, 2                     
    mov si, c

;converts each octet into binary and stores it         
    calcbinary:
    div bl                        
    add ah, '0'                    
    mov ipbinary[si], ah           
    mov ah, 00                     
    dec si
    cmp al, 00                     
    jne calcbinary

;manual insertion of dots after each octet	
    mov si, dot
    mov ipbinary[si], '.'          
    mov netbin[si], '.'
    mov brdbin[si], '.'
    mov subnet[si], '.'
    mov wildmask[si], '.' 
    
;updation of variables so as to use in next iteration    
    add e, 1                      
    mov si, e
    
    add c, 9                      
    add dot, 9                    
        
    sub f, 1
    cmp f, 0                       
    
    jne loop moving   
ret 
binary endp 

;-------------------------Broadcast address calculation--------------------     
broadcast proc
    brdcast:
    mov cl, prefix
    mov ch, 0
    mov si, 0
    brdcalc:
    mov al, netbin[si]
    mov brdbin[si], al
    inc si
    loop brdcalc
    
    printn ""
    printn ""
    print "Broadcast Address: "
    printing brdbin 
ret
broadcast endp
               
;--------------------------Network address calculation---------------------  
network proc
    cmp prefix, 8
    jle netpart1
    cmp prefix, 16
    jle part1
    jmp check1
    
    part1:
    add prefix, 1
    jmp netpart1
     
    check1:
    cmp prefix, 24
    jle part2
    jmp check2
    part2:
    add prefix, 2
    jmp netpart1
    
    check2:
    add prefix, 3
    
    netpart1:
    mov si, 0
    add cl, prefix
    mov ch, 0
    networking:
    mov bl, ipbinary[si]
    mov netbin[si], bl
    inc si
    loop networking  
    
;printing network address     
    printn ""
    printn ""
    print "Network Address: "
    printing netbin        
ret
network endp      

;---------------------------Subnet Mask calculation------------------------- 
subn proc
    mov cl, prefix
    mov ch, 0
    mov si, 0
    mov subnet[si], 31h
    sub cl, 1
    mov si, 1
    subcalc:
    cmp subnet[si], 46
    je temp
    mov subnet[si], 31h
    temp:
    inc si
    loop subcalc

;printing subnet mask address
    printn ""
    printn ""
    print "Subnet Mask Address: "
    printing subnet
ret
subn endp

host proc
        
;-----------------------First host address calculation--------------------- 
    mov si, 34
    add netbin[si], 1 ;since 1st host address is same as network address
    
;printing first host addrss
    printn ""
    printn ""
    print "First Host Address: "
    printing netbin

;-----------------------Last host address calculation---------------------- 
    mov si, 34
    mov brdbin[si], 30h ;since last host address is same as broadcast address
    
;printing last host addrss
    printn ""
    printn ""
    print "Last Host Address: "
    printing brdbin    
ret
host endp
                     
;--------------------------Wild mask calculation---------------------------
wild proc 
    mov cl, prefix
    mov ch, 0
    mov si, 0
    mov wildmask[si], 30h
    sub cl, 1
    mov si, 1
    
    wildcalc:
    cmp wildmask[si], 46
    je temp1
    mov wildmask[si], 30h
    temp1:
    inc si
    loop wildcalc
    
;printing wild mask addrss
    printn ""
    printn ""
    print "Wild Mask Address: "
    printing wildmask 
ret
wild endp

;---------------------Printing various address  passed as array------------------------------
printing MACRO array 
    local p1,p2,p3,p4,p5 ; to avoid multiple declaration
    
    mov loopCon, 0
    mov si, 0
    mov al, array[si]
    sub al, 30h
    mov bl, 2
	
    p1:
    mov ah, 0
    mul bl
    inc si
    cmp array[si], '.'
    je p2
    add al, array[si]
    sub al, 30h
    mov dl, al
    
    add loopCon, 1
    cmp loopCon, 31
    jne p1
    jmp p5
	
    p2:
    mov ah, 0
    mov al, dl
    call print_num
    cmp loopCon, 1Ah
    jle p4
	
    p3:
    inc si
    mov al, array[si]
    mov ah, 0
    add loopCon, 1
    jmp p1
	
    p4:
    putc '.'
    jmp p3
	
    p5:
    mov al, dl
    mov ah, 0
    call print_num
	
endm    
         
;-------------------------------Credits screen-----------------------------
credits proc
    call clear_screen
    
    GOTOXY 36, 2
    printn "Credits"
    GOTOXY 34, 3
    print "-----------"
    
    GOTOXY 6, 6
    printn "Mathana mathav - 19PD01"
    GOTOXY 6, 8
    printn "Mohammed Hafiz - 19PD22"
ret
credits endp

;---------------Used for pausing the program till a key is pressed---------
pause proc  
    printn ""
    printn ""
    print "Press any key.."
    mov ah, 0
    int 16h
ret
pause endp  
  
;---------------------Used at the end to end the program-------------------
endprog proc
    printn ""
    printn ""
    print "Press any key.."
    mov ah, 0
    int 16h 
    mov ah, 4ch
    int 21h 
ret
endprog endp
  
;              Various variables used during processing
loopCon db 0
dot dw 8
c dw 0
e dw 0
f dw 0
g db 10
             
;               Primary variables used for storing output
ipbinary db 35 dup('0')
netbin db 35 dup('0')
brdbin db 35 dup('1')
subnet db 35 dup('0')        ; variable's size 35 bcoz 4 octet + 3 spot
wildmask db 35 dup('1')      ; for dots so total of (4*8)+3=35
mask db 2 dup(?)
ip db 4 dup(?)
prefix db 0   

    
ret 

define_scan_num
define_print_string
define_print_num
define_print_num_uns      
define_clear_screen          
   
END



