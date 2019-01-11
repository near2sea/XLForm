//
//  XLScrollCell.m
//  Fitness
//
//  Created by Syt_ios on 2019/1/2.
//  Copyright © 2019 sythealth. All rights reserved.
//

#import "XLScrollCell.h"
#import <objc/runtime.h>

@implementation XLScrollCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

- (UIView *)createItemView:(NSInteger)idx itemViewInfo:(Class)itemViewInfo {
    NSInteger tag = 100 + idx;
    UIView *cell = (UIView*)[self.scrollView viewWithTag:tag];
    if (cell) {
        return cell;
    } else if ([itemViewInfo.class isSubclassOfClass:[UIView class]]){
        SEL sel = NSSelectorFromString(@"instance");
        Method method = class_getClassMethod(itemViewInfo, sel);
        IMP imp = method_getImplementation(method);
        UIView*(*p)(id,SEL) = (UIView*(*)(id,SEL))imp;
        return p(itemViewInfo,sel);
    }
    return nil;
}

-(void)setShowViews:(NSArray *)datas itemViewInfo:(Class)itemViewInfo
{
    [self setShowViews:datas itemViewInfo:itemViewInfo needCover:NO];
}

-(void)setShowViews:(NSArray *)datas itemViewInfo:(Class)itemViewInfo needCover:(BOOL)needCover{
    
    NSArray *subviews = [self.scrollView subviews];
    if (subviews.count) {
        for (UIView *view in subviews) {
            [view removeFromSuperview];
        }
    }
    
    CGFloat viewWidth = 0;
    CGFloat viewHeight = 0;
    CGFloat x = self.boderInset.left, y = self.boderInset.top;
    NSInteger baseTag = 100;
    
    //如果只有一条数据,则整行显示
    if (datas.count == 1) {
        self.countOfEachRow = 1;
    }
    
    for (NSInteger i = 0; i < datas.count; ++i){
        id data = [datas objectAtIndex:i];
        
        UIView *view = [self createItemView:i itemViewInfo:itemViewInfo];
        if (self.cornerRadius > 0) {
            view.layer.cornerRadius = self.cornerRadius;
            view.layer.masksToBounds = YES;
        }
        
        //计算宽度
        CGFloat newW = CGRectGetWidth(view.frame);
        if (self.widthHandler) {
            newW = self.widthHandler(data, i, i == datas.count - 1);
        } else if (self.itemCustomWidth > 0) {
            newW = self.itemCustomWidth;
        } else if (self.countOfEachRow != NSNotFound && self.countOfEachRow > 0) {
            //每个cell宽度 = (屏幕宽度 - 2个边距 - (每行个数 - 1) * item边距) / 每行个数
            newW = ([UIScreen mainScreen].bounds.size.width - self.boderInset.left * 2 - (self.countOfEachRow - 1) * self.itemOfset) / self.countOfEachRow;
        }
        //计算高度
        CGFloat newH = CGRectGetHeight(view.frame);
        if(self.itemCustomHeight > 0) {
            newH = self.itemCustomHeight;
        }else if(self.itemRatio > 0) {
            newH = newW * self.itemRatio;
        }else if(self.itemAddHeightAtWidth) {
            newH = newW + self.itemAddHeightAtWidth;
        }
        CGRect frame = CGRectMake(x, y, newW, newH);
        view.frame = frame;
        
        //赋值
        if([view respondsToSelector:@selector(setData:)]){
            [(id<XLCellViewDelegate>)view setData:data];
        }
        
        view.tag = baseTag+i;
        
        viewWidth = view.bounds.size.width;
        viewHeight = view.bounds.size.height;
        
        //垂直方向计算水平垂直偏移量
        if(self.bLayoutVertical){
            //当前列数 = 当前索引 % 每行个数
            //x = 当前列数 * （宽 + 边）
            NSUInteger curColIndex = i % self.countOfEachRow;
            x = curColIndex * (viewWidth + self.itemOfset) + self.boderInset.left;
            //当前行数 = 当前索引 / 每行个数
            //y = 当前行数 * (高 + 边)
            NSUInteger curRowIndex = i / self.countOfEachRow;
            y = curRowIndex * (viewHeight + self.itemOfset) + self.boderInset.top;
        }
        view.translatesAutoresizingMaskIntoConstraints = YES;
        view.frame = CGRectMake(x, y, viewWidth, viewHeight);
        //水平方向计算水平垂直偏移量
        if (!self.bLayoutVertical) {
            //水平偏移量
            x += viewWidth + self.itemOfset;
        }
        
        view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin;
        
        //设置view的样式
        if (self.setupViewBlock) {
            self.setupViewBlock(view, i);
        }
        [self.scrollView addSubview:view];
    }
    
    //把scrollView的contentSize设置成frame，根据内容撑满
    if (!self.bLayoutVertical) {
        CGFloat height = viewHeight + self.boderInset.top + self.boderInset.bottom;
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height]];
        //水平布局
        self.scrollView.scrollEnabled = YES;
    } else {
        //垂直布局
        //总行数 = (总数量+每行个数-1)/每行个数
        //垂直布局 总高度 = top + bottom + item的高度 * 总行数 + (总行数-1) * self.itemOfset
        NSUInteger totalRow = (datas.count + self.countOfEachRow - 1) / self.countOfEachRow;//向上取整得到总行数
        CGFloat height = self.boderInset.top + self.boderInset.bottom + totalRow * viewHeight + (totalRow - 1) * self.itemOfset;
        [self.scrollView addConstraint:[NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height]];
        self.scrollView.scrollEnabled = NO;
    }
    
    //设置scrollView的contentSize
    if (!self.bLayoutVertical) {
        x += self.boderInset.right;
        y = viewHeight + self.boderInset.top + self.boderInset.bottom;
    } else {
        y -= self.itemOfset;
        y += self.boderInset.bottom;
        x = [UIScreen mainScreen].bounds.size.width;
    }
    
    [self.scrollView setContentSize:CGSizeMake(x, y)];
}

@end
