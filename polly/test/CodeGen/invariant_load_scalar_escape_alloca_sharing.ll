; RUN: opt %loadNPMPolly -passes=polly-codegen -polly-invariant-load-hoisting=true -S < %s | FileCheck %s
;
; Verify the preloaded %tmp0 is stored and communicated in the same alloca.
; In this case, we do not reload %ncol.load from the scalar stack slot, but
; instead use directly the preloaded value stored in GlobalMap.
;
; CHECK-NOT: alloca
; CHECK:     %tmp0.preload.s2a = alloca i32
; CHECK-NOT: alloca
;
; CHECK:       %ncol.load = load i32, ptr @ncol
; CHECK-NEXT:  store i32 %ncol.load, ptr %tmp0.preload.s2a
;
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"

@ncol = external global i32, align 4

define void @melt_data(ptr %data1, ptr %data2) {
entry:
  br label %entry.split

entry.split:                                      ; preds = %entry
  %tmp0 = load i32, ptr @ncol, align 4
  %tobool.2 = icmp eq i32 %tmp0, 0
  br i1 %tobool.2, label %while.end, label %while.body.lr.ph

while.body.lr.ph:                                 ; preds = %entry.split
  br label %while.body

while.body:                                       ; preds = %while.body.lr.ph, %while.cond.backedge
  %dec3.in = phi i32 [ %tmp0, %while.body.lr.ph ], [ %dec3, %while.cond.backedge ]
  %dec3 = add nsw i32 %dec3.in, -1
  %idxprom = sext i32 %dec3 to i64
  %arrayidx = getelementptr inbounds i32, ptr %data1, i64 %idxprom
  %tmp1 = load i32, ptr %arrayidx, align 4
  %idxprom1 = sext i32 %dec3 to i64
  %arrayidx2 = getelementptr inbounds i32, ptr %data2, i64 %idxprom1
  %tmp2 = load i32, ptr %arrayidx2, align 4
  %cmp = icmp sgt i32 %tmp1, %tmp2
  br i1 %cmp, label %if.then, label %while.cond.backedge

if.then:                                          ; preds = %while.body
  %idxprom3 = sext i32 %dec3 to i64
  %arrayidx4 = getelementptr inbounds i32, ptr %data2, i64 %idxprom3
  %tmp3 = load i32, ptr %arrayidx4, align 4
  %idxprom5 = sext i32 %dec3 to i64
  %arrayidx6 = getelementptr inbounds i32, ptr %data1, i64 %idxprom5
  store i32 %tmp3, ptr %arrayidx6, align 4
  br label %while.cond.backedge

while.cond.backedge:                              ; preds = %if.then, %while.body
  %tobool = icmp eq i32 %dec3, 0
  br i1 %tobool, label %while.cond.while.end_crit_edge, label %while.body

while.cond.while.end_crit_edge:                   ; preds = %while.cond.backedge
  br label %while.end

while.end:                                        ; preds = %while.cond.while.end_crit_edge, %entry.split
  ret void
}
