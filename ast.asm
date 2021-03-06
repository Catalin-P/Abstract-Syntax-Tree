%define NODE_DIM 12

section .data
    delim db " ", 10, 0 
    is_negative dd 0

section .bss
    root resd 1

section .text

extern check_atoi
extern print_tree_inorder
extern print_tree_preorder
extern evaluate_tree
extern strtok
extern malloc
extern strdup

global create_tree
global iocla_atoi

iocla_atoi: 
    mov dword [is_negative], 0 ; suppose the number is positive
    push ebp                   ; init stack frame and push 
    mov ebp, esp               ; registers previous values on stack
    push ebx
    push ecx
    push edi
    push esi

    mov esi, [ebp + 8]         ; store string in esi
    xor eax, eax               ; clean and set registers 
    xor ebx, ebx
    xor ecx, ecx
    mov dword edi, 10          ; used to multiply eax by 10

    mov byte al, [esi]         ; store first byte of string
    inc ecx

check_if_negative:             ; check if the byte is '-' and store in al
	cmp al, '-'                ; the first digit found
	jne char_to_int
	mov dword [is_negative], 1 ; update negative flag 
	mov byte al, [esi + ecx]
	inc ecx

char_to_int:
	sub al, '0'                ; covert ASCII digit to actual digit byte

parse_number:                  ; parse string until end
	mov byte bl, [esi + ecx]   ; store the digit
	cmp bl, 0
	je update_if_negative      ; check if number must be multiplied by -1 when reaching '\0'
	inc ecx
	sub bl, '0'                ; covert ASCII digit to actual digit byte
	mul dword edi              ; recreate number from string by constantly multiplying the number
	add eax, ebx               ; made of all previously parsed digits and then adding the current digit 
	jmp parse_number

update_if_negative:            ; negate the number if the is_ negative flag is set to 1 
	cmp dword [is_negative], 1
	jne end_atoi
	mov dword ebx, eax         ; negate number by moving it in another register and then
	mov dword eax, 0           ; substracting it from 0
	sub eax, ebx 

end_atoi:                      ; restore initial values of used registers
	pop esi
	pop edi
	pop ecx
	pop ebx
    leave
    ret

create_tree:
    enter 0, 0                 ; init stack frame
    push ebx                   ; clean registers
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
	mov eax, [ebp + 8]         ; store prefix expression string in eax
    
    push delim                 ; calling strtok for the first time and restoring the stack
    push eax
    call strtok
    add esp, 8

    push eax                   ; copy token contents to new memory location
    call strdup
    add esp, 4

    push eax                   ; create the root node and set its fields
    push NODE_DIM
    call malloc
    add esp, 4

    pop ebx
    mov dword [eax], ebx       ; root -> data = string token stored at ebx
    mov dword [eax + 4], 0     ; root -> left_child = null 
    mov dword [eax + 8], 0     ; root -> right_child = null 
    
    push eax                   ; push root node in stack and save it in a global var
    mov dword [root], eax

parse_string:                  ; tokenize expression string 
	push delim
	push 0
	call strtok                ; get new token
	add esp, 8

	cmp eax, 0                 
	jne new_node
	jmp end

new_node:                      ; create a node with data from token and insert it properly   
	push eax                   ; in the expression tree
	call strdup                ; copy token data to new memory zone
    add esp, 4

    push eax                   ; allocate memory for a new node
	push NODE_DIM
    call malloc
    add esp, 4

    pop ebx                    ; init the node like the root
    mov dword [eax], ebx
    mov dword [eax + 4], 0
    mov dword [eax + 8], 0

check_operator_1:              ; check if token is an operator 
	xor ecx,ecx                ; first check: first byte of token is smaller than the ASCII code
	mov byte cl, [ebx]         ;              for the '/', which is the operator with biggest ASCII 
	cmp ecx, '/'
	jle check_operator_2
	jmp operand                ; didn't pass the first check => operand(leaf node in tree)

check_operator_2:              ; second check : the second byte in token must be '\0', to make sure
	mov byte cl, [ebx + 1]     ;                 a negative operand isn't encountered
	cmp ecx, 0
	je operator
	jmp operand                ; didn't pass the second check => operand(leaf node in tree)

operator:                      ; decide how to link parent node to the current node
	pop ebx
	cmp dword [ebx + 4], 0     
	je insert_operator_left    ; insert if left child is empty
	jmp insert_operator_right  ; insert right if left child is not empty

insert_operator_left:          ; when inserting to the left, both parent and child 
	mov dword [ebx + 4], eax   ; node must be pushed back in stack after linkage
	push ebx
	push eax
	jmp parse_string           ; continue expression parsing

insert_operator_right:         ; when inserting to the right, just the child node
	mov dword [ebx + 8], eax   ; must be added back to stack after linkage
	push eax
	jmp parse_string           ; continue expression parsing

operand:                       ; operands are leaves and should not be pushed on the stack
	pop ebx ; 
	cmp dword [ebx + 4], 0     
	je insert_operand_left     ; insert if left child is empty
	jmp insert_operand_right   ; insert right if left child is not empty

insert_operand_left:           ; push back parent node in stack after node linkage
	mov dword [ebx + 4], eax
	push ebx
	jmp parse_string           ; continue expression parsing

insert_operand_right:          ; pop parent node from stack after node linkage
	mov dword [ebx + 8], eax
	jmp parse_string           ; continue expression parsing

end:
	mov dword eax, [root]      ; restore root value 
    pop ebx
    leave
    ret
