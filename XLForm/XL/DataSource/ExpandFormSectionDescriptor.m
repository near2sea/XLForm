//
//  ExpandFormSectionDescriptor.m
//  YGTravel
//
//  Created by Mac mini on 16/4/6.
//  Copyright © 2016年 ygsoft. All rights reserved.
//

#import "ExpandFormSectionDescriptor.h"

@implementation ExpandFormSectionDescriptor

-(BOOL)isExpand
{
    return _expand;
}

-(CGFloat)heightForSectionHeader
{
    return self.height;
}
@end
