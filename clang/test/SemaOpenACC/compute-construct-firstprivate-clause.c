// RUN: %clang_cc1 %s -fopenacc -verify

typedef struct IsComplete {
  struct S { int A; } CompositeMember;
  int ScalarMember;
  float ArrayMember[5];
  void *PointerMember;
} Complete;
void uses(int IntParam, short *PointerParam, float ArrayParam[5], Complete CompositeParam) {
  int LocalInt;
  short *LocalPointer;
  float LocalArray[5];
  Complete LocalComposite;
  // Check Appertainment:
#pragma acc parallel firstprivate(LocalInt)
  while(1);
#pragma acc serial firstprivate(LocalInt)
  while(1);
  // expected-error@+1{{OpenACC 'firstprivate' clause is not valid on 'kernels' directive}}
#pragma acc kernels firstprivate(LocalInt)
  while(1);

  // Valid cases:
#pragma acc parallel firstprivate(LocalInt, LocalPointer, LocalArray)
  while(1);
#pragma acc parallel firstprivate(LocalArray[2:1])
  while(1);

#pragma acc parallel firstprivate(LocalComposite.ScalarMember, LocalComposite.ScalarMember)
  while(1);

  // expected-error@+1{{OpenACC variable is not a valid variable name, sub-array, array element, member of a composite variable, or composite variable member}}
#pragma acc parallel firstprivate(1 + IntParam)
  while(1);

  // expected-error@+1{{OpenACC variable is not a valid variable name, sub-array, array element, member of a composite variable, or composite variable member}}
#pragma acc parallel firstprivate(+IntParam)
  while(1);

  // expected-error@+1{{OpenACC sub-array length is unspecified and cannot be inferred because the subscripted value is not an array}}
#pragma acc parallel firstprivate(PointerParam[2:])
  while(1);

  // expected-error@+1{{OpenACC sub-array specified range [2:5] would be out of the range of the subscripted array size of 5}}
#pragma acc parallel firstprivate(ArrayParam[2:5])
  while(1);

  // expected-error@+2{{OpenACC sub-array specified range [2:5] would be out of the range of the subscripted array size of 5}}
  // expected-error@+1{{OpenACC variable is not a valid variable name, sub-array, array element, member of a composite variable, or composite variable member}}
#pragma acc parallel firstprivate((float*)ArrayParam[2:5])
  while(1);
  // expected-error@+1{{OpenACC variable is not a valid variable name, sub-array, array element, member of a composite variable, or composite variable member}}
#pragma acc parallel firstprivate((float)ArrayParam[2])
  while(1);

  // expected-error@+1{{OpenACC 'firstprivate' clause is not valid on 'loop' directive}}
#pragma acc loop firstprivate(LocalInt)
  for(int i = 5; i < 10;++i);
}
