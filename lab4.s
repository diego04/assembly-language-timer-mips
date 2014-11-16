
	
#---------------------------------------------------------------
# Assignment:           4
# Due Date:             March 17, 2014
# Name:                 Kevin De Asis
# Unix ID:              deasis
# Lecture Section:      Lec B1
# Instructor:           Jacqueline Smith
# Lab Section:          H02
# Teaching Assistant:   Adam St. Arnaud
#---------------------------------------------------------------

#----------------------------------------------------------------------
#
#                
#	This program implements a stopwatch using the coprocessor 0. 
#It uses interrupts to increment the clock's seconds. Also, when the
#the charachters r, s, and q are typed in the keyboard interrupts are
#also raised. Keyboard interrupt are implemented by using polling in 
#the program. An exception handler is used for timer interrupts when
#the register $9 and $11 of coprocessor 0 are equal, which then goes  
#back to the "main" and tells it to increment seconds. Charachter 's'
#stops or resumes the clock. Charachter 'q' exits the stopwatch. 
#Charachter 'r' restarts the clock.
#
#
#
# Register Usage
#
#			$a0 see if you need to append the timer
#			$t0 is array
#			$t1 is pointer to element of array
#			$t2 is address of printer
#			$t3 address of kebyboard control
#			$t4 keyboard control bits
#			$t5 keyboard control checker
#			$t6 keyboard input
#			$t7 status register for coprocessor0
#			$t8 coprocessor 0 register $9
#			$t9 coprocessor 0 register $11
#			$s0 ascii for q
#			$s1	ascii for r
#			$s2	ascii for s
#			$s3 ascii for backspace
#			$s4	ascii for zero
#			$s5 start or restart timer variable, if first bit is 1 start timer, if 0 pause
#			$s6 is 1 for checking s5
#			$s7 a checker
#			$t7, t8, t9reused for manipulating array
#----------------------------------------------------------------------


################################
# Handler Data #################
################################

	.kdata
ktemp:	.space 16


###############################
# Exception Interrupt Handler #
###############################

	# Overwrites previous handler defined in exceptions.s
	.ktext 0x80000180
	.set noat
	move $k0, $at
	.set at

	la $k1, ktemp
	sw $a0, 0($k1)
	sw $a1, 4($k1)
	sw $v0, 8($k1)
	sw $ra, 12($k1)


	mfc0 $a0, $13  # Obtain cause register
	andi $v0, $a0, 0x7C  #Check for interrupts
	beq $v0, $zero, steps #if zero it is interrupt so jump
	j finish
	
#############just a bunch of cleaning up in steps#################
steps:	
	mfc0 $a0, $13 
	andi $v0, $a0, 0x8000

	xor $a0, $a0, $v0
	mtc0 $a0, $13 
	mtc0 $zero, $9
		
	addi $a0 $zero 100
	mtc0 $a0 $11
		

finish:

	la $k1, ktemp
	lw $a0, 0($k1)
	lw $a1, 4($k1)
	lw $v0, 8($k1)
	lw $ra, 12($k1)

	.set noat
	move $at, $k0
	.set at
	mfc0 $k0, $12  # Status
	ori $k0, 0x01  # re-enable interrupts
	mtc0 $k0, $12  # Status
	addi $t9 $zero 1

	eret

#############################################################
##############   MAIN ######################################
#############################################################
	.data
display:
	.byte 8,8,8,8,8,48,48,58,48,48,0
	

.text
.globl __start
__start:

		addi 	$s0 $zero 113 
		addi 	$s1 $zero 114
		addi 	$s2 $zero 115
		addi	$s3 $zero 8						#ascii for backspace
		addi	$s4 $zero 48						#ascii for zero
		add	$s5 $zero $zero		
		addi	$s6 $zero 1
		addi	$s7 $zero 1

##################################################################
#display initial time
##################################################################

		la 	$t0 display				#load array of str to $t0
loop1:		lb	$t1 0($t0)				#load one ascii in display      
		beqz	$t1 Afterinitialdisplay			#if end marker stop displaying
		
			
poll1:	
		lw 	$t2  0xffff0008				#load control register of display
		andi	$t2  $t2, 0x01				#whatever is in that control register and immediate 1
		beqz	$t2  poll1				#beqz meaning if 0 means not ready, no interrupts
				
		sw 	$t1, 0xffff000c				#print display
		addi	$t0, $t0, 1
		j	loop1	

#################################################################
#########Enable Interrupt
#################################################################
		###KEYBOARD INTERRUPT
		###lui 	$t3, 0xFFFF					#enable interrupt
		###lw		$t4, 0($t3)				#enable interrupt
		###ori		$t4, $t4, 2	 			#enable interrupt
		###sw		$t4, 0($t3)				#enable interrupt

Afterinitialdisplay:
		#mfc0	$t7, $12  					# Obtain Status
		#ori 	$t7, 0x8001 					# interrupts enable only for timer
		#mtc0 	$t7, $12  					# Move to Status

		#addi	$t7, $zero, 100					#set coprocessor0 register 11 to a second
		#mtc0	$t7, $11					#set coprocessor0 register 11 to a second
			
		#addi	$t8, $zero, 0					#set coprocessor0 register 9 to zero
		#mtc0	$t8, $9						#set coprocessor0 register 9 to zero
		
		#######
		add	$t9 $zero	$zero
#################################################################
#########Wait if keyboard interrupt happened
#################################################################

		j	arrayend
		
ShowTime:
		la 	$t0 display					#load array of str to $t0
loop:		lb	$t1,0($t0)
		beqz	$t1 arrayend
		
			
poll:	
		lw 	$t2 0xffff0008					#load control register of display
		andi	$t2 $t2 0x01					#whatever is in that control register and immediate 1
		beqz	$t2, poll					#beqz meaning if 0 means not ready, no interrupts
				
		sw 	$t1, 0xffff000c					#print display
		addi	$t0, $t0, 1
		j	loop						
		
	
arrayend:
		#wait for keyboard input
		bgtz  	$t9  addtime				
		lui 	$t3, 0xFFFF
		lw	$t4, 0($t3)
		andi	$t5, $t4, 0x0001
		beq	$t5, $zero, arrayend

		#####
		lw	$t6, 4($t3)

		beq 	$s0 $t6 inputq					#user inputs q in the keyboard
		beq 	$s1 $t6 inputr					#user inputs r in the keyboard
		beq 	$s2 $t6 inputs					#user inputs s in the keyboard
		j 	arrayend					#keep waiting for keyboard interrupts

addtime:
		jal Addsecond
		j   arrayend
		
########################## Exit TIMER  ############################

inputq:
		 li      $v0, 10					# terminate program run and
    	    	syscall 
    	
    	
########################## RESET TIMER  ###########################
inputr:

		la 	$t0 display					#load array of str to $t0
		sb	$s3 0($t0)
		sb	$s3 1($t0)
		sb	$s3 2($t0)
		sb	$s3 3($t0)
		sb	$s3 4($t0)
		sb	$s4 5($t0)
		sb 	$s4 6($t0)
		sb  	$s4 8($t0)
		sb	$s4 9($t0)		
		j	ShowTime	
		
######################## Pause or Start the Timer###################
	#turn off or on timer interrupt	
	#does nothing wait for keyboard interrupt for another s r or q
	#if s5 is  1  pause if 0 go start time
##########################################

inputs:
		addi	 $s5 $s5 1
		andi	 $s5 $s5 1
		beq      $s5 $zero norunclock
		
		mfc0	$t7, $12  					# Status
		ori 	$t7, 0x01 					# interrupts enable
		mtc0 	$t7, $12  					# Status
		
		addi	$t7, $zero, 100					#set coprocessor0 register 11 to a second
		mtc0	$t7, $11					#set coprocessor0 register 11 to a second
		
			
		addi	$t8, $zero, 0					#set coprocessor0 register 9 to zero
		mtc0	$t8, $9						#set coprocessor0 register 9 to zero
		j		arrayend	
		
##########DISABLE INTERRUPTS
norunclock:
			
		mfc0	$t7, $12  					# Status
		andi 	$t7, 0xFFFD 					# interrupts disabled
		mtc0 	$t7, $12  					# Status
		
		addi	$t7, $zero, 0					#set coprocessor0 register 11 to 0
		mtc0	$t7, $11					#set coprocessor0 register 11 to 0
			
		addi	$t8, $zero, 0					#set coprocessor0 register 9 to one
		mtc0	$t8, $9						#set coprocessor0 register 9 to one
		
		j		arrayend	

########################## Subroutine display  ############################

Addsecond:
				
	
		la 	$t0 display				#load array of str to $t0
		lb	$t1 0($t0)				#load one ascii in display      

		
		addi		$t7 $zero 57				#semi colon ascii
		
		lb		$t1 9($t0)				#load the second from array
		addi 		$t1 $t1 1				#
		bgt 	    	$t1 $t7 resetsecond			#if second is greater than 9 goto resetseconds
		sb 		$t1 9($t0)				#store zero in array

		
	secc:
		lb		$t1	0($t0)				#PRINTING
		beqz		$t1     switch
		
			
	poll3:	
		lw 		$t2 0xffff0008				#load control register of display
		andi		$t2 $t2 0x01				#whatever is in that control register and immediate 1
		beqz		$t2	poll3				#beqz meaning if 0 means not ready, no interrupts
				
		sw 		$t1	0xffff000c			#print display
		addi		$t0	$t0 1
		j		secc		
		
switch:

	
		add		$t9	$zero $zero
		jr		$ra
		
resetsecond:
		sb 		$s4 9($t0)				#store zero in array
		lb		$t1 8($t0)				#load ten seconds from the array					

		addi		$t1 $t1 1				#add another tenseconds
		addi         	$t8 $zero 54				#check condition for ten seconds
		beq		$t1 $t8 resettensecond			#if greater than 5 reset ten seconds to zero
		sb		$t1 8($t0)  
		j		secc
resettensecond:
		
		addi		$t1	$zero	48		
		sb		$t1	8($t0)
		lb		$t1	 	6($t0)
		addi 		$t1	$t1	1
		addi		$t8	$zero 58	
		beq		$t1 $t8	resetminute
		sb		$t1 6($t0)
		j		secc
		
resetminute:
		
		addi		$t1	$zero	48
		sb		$t1	6($t0)
		lb		$t1 5($t0)
		addi		$t1 $t1 1
		sb		$t1 5($t0)
		j 		secc


##########################	Reference		 ##########################
#http://ldc.usb.ve/~adiserio/ci3815/Sep2005/Interrupts.pdf
#http://jjc.hydrus.net/cs61c/handouts/interrupts1.pdf
#http://www.cs.nott.ac.uk/~txa/g51csa/l
