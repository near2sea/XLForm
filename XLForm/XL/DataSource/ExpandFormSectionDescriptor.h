//
//  ExpandFormSectionDescriptor.h
//  YGTravel
//
//  Created by Mac mini on 16/4/6.
//  Copyright © 2016年 ygsoft. All rights reserved.
//

#import "XLForm.h"

@protocol ExpandFormSectionDescriptorDelegate <NSObject>
@property (nonatomic, assign, getter=isExpand) BOOL expand;
@optional
- (CGFloat)heightForSectionHeader;
@end

@interface ExpandFormSectionDescriptor : XLFormSectionDescriptor<ExpandFormSectionDescriptorDelegate>
@property (nonatomic, assign, getter=isExpand) BOOL expand;
@property (nonatomic, assign) CGFloat height;
@end
