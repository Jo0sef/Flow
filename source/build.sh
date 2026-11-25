cd /tmp/flow
cat p1.m p2.m p3a.m p3e.m p3x.m p4a.m p3t.m p4p.m p4b.m p5t.m p5a.m p5b.m > main.m
SDK=/tmp/ios/sdks/iPhoneOS16.5.sdk
/tmp/ios/LLVM-23.1.6-Linux-X64/bin/clang -target arm64-apple-ios15.0 -isysroot $SDK -fobjc-arc -O2 -Wno-deprecated-declarations -Wno-unguarded-availability-new -U__ARM_NEON -U__ARM_NEON__ -c main.m -o main.o 2>&1 | grep -E "error|warning: (incompatible|implicit|unused var)" | head -${1:-40}
