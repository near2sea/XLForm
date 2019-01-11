//
//  XLScrollCell.h
//  Fitness
//
//  Created by Syt_ios on 2019/1/2.
//  Copyright © 2019 sythealth. All rights reserved.
//

#import "XLFormBaseCell.h"

@protocol XLCellViewDelegate <NSObject>
@optional
- (void)setData:(id)data;
@end

typedef void (^SetupViewBlock)(UIView *view, NSInteger index);

//动态计算每个item的宽度
typedef CGFloat (^WidthCalculatorHandler)(id data, NSInteger index, BOOL isLast);

@interface XLScrollCell : XLFormBaseCell
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

/**scroview 上下左右的边距*/
@property (nonatomic, assign) UIEdgeInsets boderInset;

/**item之间的间隔*/
@property (nonatomic) CGFloat itemOfset;

/**itemp宽高比率*/
@property (nonatomic) CGFloat itemRatio;

/**item的自定义宽度*/
@property (nonatomic) CGFloat itemCustomWidth;

/**item的自定义高度*/
@property (nonatomic) CGFloat itemCustomHeight;

/**item在宽度的基础上计算高度*/
@property (nonatomic) CGFloat itemAddHeightAtWidth;

/**是否垂直布局*/
@property (nonatomic, assign) BOOL bLayoutVertical;

/** 每行个数, -1：保持nib文件的宽度，>0：表示每行个数 */
@property (nonatomic, assign) NSInteger countOfEachRow;

/**圆角弧度*/
@property (nonatomic, assign) CGFloat cornerRadius;

/**设置view的样式*/
@property (nonatomic, copy) SetupViewBlock setupViewBlock;

/**动态设置子视图的宽度*/
@property (nonatomic, copy) WidthCalculatorHandler widthHandler;

-(void)setShowViews:(NSArray *)datas itemViewInfo:(Class)itemViewInfo;

-(void)setShowViews:(NSArray *)datas itemViewInfo:(Class)itemViewInfo needCover:(BOOL)needCover;
@end
