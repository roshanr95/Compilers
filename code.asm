void main() {
l1: move(6,eax);
l2: move(5,ebx);
l3: move(4,ecx);
l4: move(0,edx);
l5: pushi(eax);
l6: move(3,eax);
l7: pushi(ebx);
l8: loadi(ind(ebp,-4),ebx);
l9: addi(ebx,eax);
l10: loadi(ind(ebp,-4),ebx);
l11: addi(ebx,eax);
l12: addi(eax,edx);
l13: loadi(ind(ebp,-4),eax);
l14: addi(eax,edx);
l15: addi(edx,ecx);
l16: loadi(ind(esp),ebx);
popi(1);
l17: addi(ecx,ebx);
l18: loadi(ind(esp),eax);
popi(1);
l19: addi(ebx,eax);
}

