//
//  XLFormDataSource.h
//  Linkage
//
//  Created by lihaijian on 16/3/28.
//  Copyright © 2016年 LA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XLForm.h"
@protocol XLFormDataSourceDelegate <NSObject>
@optional
-(void)didSelectFormRow:(XLFormRowDescriptor *)formRow;
-(void)deselectFormRow:(XLFormRowDescriptor *)formRow;
-(void)reloadFormRow:(XLFormRowDescriptor *)formRow;
-(UITableViewCell<XLFormDescriptorCell> *)updateFormRow:(XLFormRowDescriptor *)formRow;

-(NSDictionary *)formValues;
-(NSDictionary *)httpParameters;

-(XLFormRowDescriptor *)formRowFormMultivaluedFormSection:(XLFormSectionDescriptor *)formSection;
-(void)multivaluedInsertButtonTapped:(XLFormRowDescriptor *)formRow;
-(UIStoryboard *)storyboardForRow:(XLFormRowDescriptor *)formRow;

-(NSArray *)formValidationErrors;
-(void)showFormValidationError:(NSError *)error;

-(UITableViewRowAnimation)insertRowAnimationForRow:(XLFormRowDescriptor *)formRow;
-(UITableViewRowAnimation)deleteRowAnimationForRow:(XLFormRowDescriptor *)formRow;
-(UITableViewRowAnimation)insertRowAnimationForSection:(XLFormSectionDescriptor *)formSection;
-(UITableViewRowAnimation)deleteRowAnimationForSection:(XLFormSectionDescriptor *)formSection;

// highlight/unhighlight
-(void)beginEditing:(XLFormRowDescriptor *)rowDescriptor;
-(void)endEditing:(XLFormRowDescriptor *)rowDescriptor;

-(void)ensureRowIsVisible:(XLFormRowDescriptor *)inlineRowDescriptor;
@end


@interface XLFormDataSource : NSObject<UITableViewDataSource,UITableViewDelegate, XLFormDescriptorDelegate,XLFormDataSourceDelegate>
@property (nonatomic, strong) XLFormDescriptor *form;
@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, weak) UITableView *tableView;

- (instancetype)initWithViewController:(UIViewController *)viewController tableView:(UITableView *)tableView;
- (instancetype)initWithTableView:(UITableView *)tableView;
@end
