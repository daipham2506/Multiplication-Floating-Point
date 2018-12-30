###################################################
# +) Assignment 1                                 #     
# +) Course: Aritecture Computer                  #
# +) Student 1: Pham Tan Dai - 1710929		  #
# +) Student 2: Cao Thanh Nhan - 1710214 	  #
# +) Student 3: Le Thi Thanh Thao - 1713177 	  #
# +) Instructor: Nguyen Xuan Minh	 	  #
# +) Topic 3: Floating Point Multiplication       #
###################################################

####################### Data segment ####################### 
.data

	A: 		.float 	0
	B: 		.float 	0
	result: 	.float 	0

	txt_KetQua: 	.asciiz "Ket qua A x B = " 
		
	#cac cau nhac du lieu 
	Nhac_A: 	.asciiz "Nhap so thuc A : "
	Nhac_B: 	.asciiz "Nhap so thuc B : "	
	
####################### Code segment #######################

.text
.globl main
main: # main program entry

	la 	$a0,Nhac_A 			# Nhac nhap A
	li 	$v0, 4
	syscall

	li 	$v0, 6 				# Read float
	syscall 				# $f0 = value read
	swc1 	$f0, A  			# A = gia tri vua doc


	la 	$a0,Nhac_B  			# Nhac nhap B
	li 	$v0, 4
	syscall

	li 	$v0, 6 				# Read float
	syscall 				# $f0 = value read
	swc1 	$f0, B  		 	# B = gia tri vua doc

	la  	$s0, A				# $s0 = dia chi o nho chua so A
	lw  	$a0, 0($s0)			# $s0 = A
	
	la 	$s1, B				# $s1 = dia chi o nho chua so B
	lw  	$a1, 0($s1)			# $s1 = B
	
	
	# Goi ham nhan 2 so thuc ( tra ket qua ve $f0 )
	jal 	multiplication
	mov.s 	$f12, $f0
	
	#Xuat ket qua ra Console
	la 	$a0, txt_KetQua
	li 	$v0, 4
	syscall
	
	li 	$v0,2   			# xuat ket qua
	syscall
				
	li $v0, 10 				# Exit program
	syscall


#=================Ham nhan 2 so thuc A , B===================
	# float multiplication(float A,float B)
	# $a0 = A , $a1 = B
	# $f0 tra ve
	
multiplication:	
## Tim S trong SEM ## (1 bit)
# + Luu bit dau cua tich (Luu vao bit dau tien vao $t0 0:duong - 1:am)
# => Su dung phep XOR de xac dinh dau
sign_bit:
	xor 	$t0, $a0, $a1			# 00-0 11-0 01-1 10-1
	andi 	$t0, $t0, 0x80000000		# Luu bit dau vao $t0 (bit dau tien)

#--------------------------------------------------------#
exponent:
## Tim E trong SEM ## (8 bit)
# - Tinh E (tam thoi) cua ket qua
# + Er = (Ea-127) + (Eb-127) + 127  
#      = Ea + Eb - 127
# + Tinh Ea
	andi	$t3, $a0, 0x7F800000		# Luu 8 bit Exponent cua so A vao $t3
# + Tinh Eb
	andi	$t4, $a1, 0x7F800000		# Luu 8 bit Exponent cua so B vao $t4
# + Tính Er
# + Er = Ea + Eb - 127
	addu  	$t1, $t3, $t4			# Thuc hien cong hai Exponent
	srl	$t1, $t1, 23			# Dich sang phai 23 bit de thuc hien tru 127 vao ket qua
	subi 	$t1, $t1, 127			# Tru di 127
#--------------------------------------------------------#
## Kiem tra tran duoi (Underflow) ##
##          tran tren (Overflow)  ##
	blt 	$t1, $zero, Underflow		# Neu Exponent < 0 di den Underflow
	bgt 	$t1, 254, Overflow		# Neu Exponent > 254 di den Overflow
# Sau khi thuc hien $t1 chua 8 bit Exponent
#--------------------------------------------------------#
Mantissa:
## Tim M trong SEM (23 bit)
# + Tinh Ma
	andi	$t3, $a0, 0x007FFFFF		# Loai bo cac bit sign va Exponent cua A luu vao $t3
# + Tinh Mb
	andi	$t4, $a1, 0x007FFFFF		# Loai bo cac bit sign va Exponent cua B luu vao $t4
# + Them so 1 vao truoc 23 bit mantissa cua A va B
	ori	$t3, $t3, 0x00800000
	ori	$t4, $t4, 0x00800000
# + Nhan $t3 x $t4
	multu 	$t3, $t4
	mflo 	$t5   				# luu LO Register trong $t5
	mfhi 	$t6   				# luu HI Register trong $t6
# + So sanh can thiet tang Exponent hay khong
	andi	$t7, $t6, 0xFFFF8000		# Xoa het 14 bit chac chan thuoc Mantissa va bit dau tien luu vao $t7
	beqz	$t7, case2			# Neu $t7 = 0 thi di den case2 
# + Chia 2 truong hop co nho va khong nho
case1:						# TH co nho
	addi	$t1, $t1, 1			# Tang exponent len 1
	andi	$t6, $t6, 0x00007FFF		# Lay 15 bit cua HI REG
	andi	$t5, $t5, 0xFF000000		# Lay 8 bit cua LO REG
	sll 	$t6, $t6, 8			# Doi lai vi tri dung
	srl 	$t5, $t5, 24			# Doi lai vi tri dung
	j	next				# Di den next
case2:
	andi	$t6, $t6, 0x00003FFF		# Lay 14 bit cua HI REG
	andi	$t5, $t5, 0xFF800000		# Lay 9 bit cua LO REG
	sll 	$t6, $t6, 9			# Doi lai vi tri dung
	srl 	$t5, $t5, 23			# Doi lai vi tri dung
next:
# + Luu mantissa vào $t2
	or 	$t2, $t6, $t5
#--------------------------------------------------------#
Merge:
## Chuan hoa ket qua, luu ket qua vào thanh ghi s2 va luu vao o nho result ##
	sll	$t1, $t1, 23			# Doi $t1 lai cho dung vi tri
	or	$s2, $t0, $t1			# Nhap sign_bit voi Exponent vao $s2
	or	$s2, $s2, $t2			# Nhap mantissa vao $s2
	sw 	$s2, result			# Luu vao result
	j	End				# Di den End
#--------------------------------------------------------#
## Xu ly tran duoi, tra ve so 0 ##
Underflow: 
	j 	End
## Xu ly tran tren, tra ve Infinity ##
Overflow :
	li 	$t1,255				# gan Exponent = 255
	j 	Merge				
#--------------------------------------------------------#

End:
	lwc1 	$f0, result			# Load ket qua vao $f0
	jr 	$ra				# Tro lai chuong trinh chinh


