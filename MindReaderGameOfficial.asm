# The goal of this program is to take the users to think of a number between 1-63. 
# Six random cards will be shown to the user that contains 32 numbers
# they of thinking of. The program will then find the number they are "thinking" of after the end of the 6th slide. 
# CS 2340.501 Final Project- Mind Reader Game
# By: Arjun Balaji, Josh Ortiz, and Vaishnavi Rao


#	Set register to random value
.macro setrandom (%generator, %register, %max)
	li	$a0, %generator
	move	$a1, %max
	li	$v0, 42
	syscall
	move	%register, $a0
.end_macro

#	sysint prints int
.macro sysint (%x)
	li $v0, 1
	add $a0, $zero, %x
	syscall
.end_macro

#	sysout prints
.macro sysout (%str)
	.data
	text: .asciiz %str
	.text
	li $v0, 4
	la $a0, text
	syscall
.end_macro

#	Set stack value to register
.macro storeStack (%offset, %register)
	sw	%register, %offset($sp)
.end_macro

#	Get stack value into register
.macro loadStack (%offset, %register)
	lw	%register, %offset($sp)
.end_macro

#	Pop stack based on stored width
.macro popStack(%bytes)
	addi	$sp, $sp, %bytes
.end_macro

#	Exit program
.macro terminate
	li	$v0,10
	syscall
.end_macro
.data


#this will display the amount of cards in the Mind Reader Game
length: .word 6


.text
.globl main
main:

	li	$s0, 0
	lw 	$s1, length
	li 	$s4, 1
	sllv	$s4, $s4, $s1
	
	# this is our while loop which will corelate to domain
whileLoop:

	slt	$t0, $s0, $s1
	addi	$s0, $s0, 1
	bnez 	$t0, mainDoWhile
	j	postwhileLoop
	
mainDoWhile:
	
	setrandom(0, $t1, $s1)
	# this will be the masking part discussed in the video where
	# it force certain bits to zero or one within some other value
	li 	$s2, 1
	sllv	$s2, $s2, $t1
	and 	$t0, $s2, $s3
	bnez	$t0, mainDoWhile	
	or	$s3, $s3, $s2
	
	#this will now jump to 'displayCard'
	move 	$a0, $s2
	move	$a1, $s4
	jal 	displayCard

	#this is will be a repeating question to the user until all six slides are passed		
	sysout("Is your number in this card? (Y/N): ")
	#jumps to checkBoolean to validate users input
	jal 	checkBoolean
		
	# If input was y or Y
	beqz	$v0, newLine
	# output($s6) = output | mask
	or	$s7, $s7, $s2
	
newLine:
		
	# print new line
	sysout("\n")
	# this will have the user jump back to the next
	j whileLoop
	
postwhileLoop:
	
	# prints final number that is in $s7
	sysout("Your number is: ")
	sysint($s7)
	sysout("\n")
	
	terminate

#checkBoolean will determine  if users input is valid or not
# if user inputs a wrong character, the user is then prompted to try again UNTIL input is valid
checkBoolean:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)	
	li 	$v0, 12
	syscall

	# this will determine if user typed N or n
	li 	$t0, 78
	beq	$v0, $t0, validateN
	addi	$t0, $t0, 32
	beq	$v0, $t0, validateN
	#this validates if uesr typed in Y or y 
	li 	$t0, 89
	beq	$v0, $t0, validateY
	addi	$t0, $t0, 32
	beq	$v0, $t0, validateY
	#if user typed in incorrect input, loop until input is Valid
	sysout("\nError: Incorrect Input, Try: Y, y, N, n\nTry Again!: ")
	jal checkBoolean
	
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
	
	# Y/y will return true
validateY:
	li	$v0, 1
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
	
	# N/n will return false
validateN:
	li	$v0, 0
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
	
displayCard:

	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	# move stored values to stack
	subi	$sp, $sp, 32
	storeStack(0, $s2)
	storeStack(4, $s4)
	storeStack(8, $s5)
	storeStack(12, $s6)
	storeStack(16, $s7)
	storeStack(20, $s1)
	storeStack(24, $s0) 
	storeStack(28, $s7) 
	
	# move input to stored
	move	$s2, $a0
	move	$s4, $a1
	
	#determine final card number
	move $a0, $s2
	jal log2
	addi $s1, $v0, 1

	# This will print what card we are currently printing out
	sysout("\nCard: ")
	sysint($s1)
	sysout("\n")
	

whileLoopPrint:
	slt 	$t0, $s5, $s4
	bnez	$t0, doPrint
	j printLoop
	
doPrint:
	and	$t1, $s5, $s2
	bne	$t1, $s2, printIgnore
	sysint($s5)
	sysout("\t")
	addi	$s6, $s6, 1
		
	#while printing the program will add a new line and reset after the 8th number
	slti	$t1, $s6, 8
	bnez	$t1, printIgnore
	sysout("\n")
	li	$s6, 0
		
printIgnore:
	#increment the index
	addi	$s5, $s5, 1
	j whileLoopPrint
		
printLoop:
	
	# reload stack and return
	loadStack(0, $s2)
	loadStack(4, $s4)
	loadStack(8, $s5)
	loadStack(12, $s6)
	loadStack(16, $s7)
	loadStack(20, $s1)
	loadStack(24, $s0) 
	loadStack(28, $s7) 
	popStack(32)
	
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra
	
log2:
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	li $v0, -1
		
logLoop:
	beqz $a0, terminatelog
	addi $v0, $v0, 1
	srl $a0, $a0, 1
	j logLoop
	
terminatelog:		
	lw 	$ra, ($sp)
	addi 	$sp, $sp, 4
	jr 	$ra


