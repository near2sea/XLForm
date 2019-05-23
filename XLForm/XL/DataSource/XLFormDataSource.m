//
//  XLFormDataSource.m
//  Linkage
//
//  Created by Mac mini on 16/3/28.
//  Copyright © 2016年 LA. All rights reserved.
//
#import "XLFormDataSource.h"
#import "ExpandFormSectionDescriptor.h"
#import "XLFormRowDescriptor.h"

@interface XLFormRowDescriptor(_XLFormDataSource)

@property (readonly) NSArray * observers;
-(BOOL)evaluateIsDisabled;
-(BOOL)evaluateIsHidden;

@end

@interface XLFormSectionDescriptor(_XLFormDataSource)
-(BOOL)evaluateIsHidden;
@end

@interface XLFormDescriptor (_XLFormDataSource)

@property NSMutableDictionary* rowObservers;

@end

@implementation XLFormDataSource

- (instancetype)initWithViewController:(UIViewController *)viewController tableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        self.viewController = viewController;
        self.tableView = tableView;
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
    }
    return self;
}

-(void)setForm:(XLFormDescriptor *)form
{
    _form.delegate = nil;
    [self.tableView endEditing:YES];
    _form = form;
    _form.delegate = self;
    [_form forceEvaluate];
    if ([self.viewController isViewLoaded]){
        [self.tableView reloadData];
    }
}

#pragma mark - XLFormDescriptorDelegate

-(void)formRowHasBeenAdded:(XLFormRowDescriptor *)formRow atIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:[self insertRowAnimationForRow:formRow]];
    [self.tableView endUpdates];
}

-(void)formRowHasBeenRemoved:(XLFormRowDescriptor *)formRow atIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:[self deleteRowAnimationForRow:formRow]];
    [self.tableView endUpdates];
}

-(void)formSectionHasBeenRemoved:(XLFormSectionDescriptor *)formSection atIndex:(NSUInteger)index
{
    [self.tableView beginUpdates];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:[self deleteRowAnimationForSection:formSection]];
    [self.tableView endUpdates];
}

-(void)formSectionHasBeenAdded:(XLFormSectionDescriptor *)formSection atIndex:(NSUInteger)index
{
    [self.tableView beginUpdates];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:[self insertRowAnimationForSection:formSection]];
    [self.tableView endUpdates];
}

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue
{
    [self updateAfterDependentRowChanged:formRow];
    [self updateFormRow:formRow];
}

-(void)formRowDescriptorPredicateHasChanged:(XLFormRowDescriptor *)formRow oldValue:(id)oldValue newValue:(id)newValue predicateType:(XLPredicateType)predicateType
{
    if (oldValue != newValue) {
        [self updateAfterDependentRowChanged:formRow];
    }
}

-(void)updateAfterDependentRowChanged:(XLFormRowDescriptor *)formRow
{
    NSMutableArray* revaluateHidden   = self.form.rowObservers[[formRow.tag formKeyForPredicateType:XLPredicateTypeHidden]];
    NSMutableArray* revaluateDisabled = self.form.rowObservers[[formRow.tag formKeyForPredicateType:XLPredicateTypeDisabled]];
    for (id object in revaluateDisabled) {
        if ([object isKindOfClass:[NSString class]]) {
            XLFormRowDescriptor* row = [self.form formRowWithTag:object];
            if (row){
                [row evaluateIsDisabled];
                [self updateFormRow:row];
            }
        }
    }
    for (id object in revaluateHidden) {
        if ([object isKindOfClass:[NSString class]]) {
            XLFormRowDescriptor* row = [self.form formRowWithTag:object];
            if (row){
                [row evaluateIsHidden];
            }
        }
        else if ([object isKindOfClass:[XLFormSectionDescriptor class]]) {
            XLFormSectionDescriptor* section = (XLFormSectionDescriptor*) object;
            [section evaluateIsHidden];
        }
    }
}

#pragma mark - XLFormViewControllerDelegate
-(NSDictionary *)formValues
{
    return [self.form formValues];
}

-(void)didSelectFormRow:(XLFormRowDescriptor *)formRow
{
    if ([[formRow cellForTableView:self.tableView] respondsToSelector:@selector(formDescriptorCellDidSelectedWithFormController:)]){
        if (self.tableView && self.viewController) {
            [[formRow cellForTableView:self.tableView] formDescriptorCellDidSelectedWithFormController:self.viewController];
        }
    }
    [self deselectFormRow:formRow];
}

-(UITableViewRowAnimation)insertRowAnimationForRow:(XLFormRowDescriptor *)formRow
{
    if (formRow.sectionDescriptor.sectionOptions & XLFormSectionOptionCanInsert){
        if (formRow.sectionDescriptor.sectionInsertMode == XLFormSectionInsertModeButton){
            return UITableViewRowAnimationNone;
        }
        else if (formRow.sectionDescriptor.sectionInsertMode == XLFormSectionInsertModeLastRow){
            return YES;
        }
    }
    return UITableViewRowAnimationNone;
}

-(UITableViewRowAnimation)deleteRowAnimationForRow:(XLFormRowDescriptor *)formRow
{
    return UITableViewRowAnimationNone;
}

-(UITableViewRowAnimation)insertRowAnimationForSection:(XLFormSectionDescriptor *)formSection
{
    return UITableViewRowAnimationNone;
}

-(UITableViewRowAnimation)deleteRowAnimationForSection:(XLFormSectionDescriptor *)formSection
{
    return UITableViewRowAnimationNone;
}

-(XLFormRowDescriptor *)formRowFormMultivaluedFormSection:(XLFormSectionDescriptor *)formSection
{
    if (formSection.multivaluedRowTemplate){
        return [formSection.multivaluedRowTemplate copy];
    }
    XLFormRowDescriptor * formRowDescriptor = [[formSection.formRows objectAtIndex:0] copy];
    formRowDescriptor.tag = nil;
    return formRowDescriptor;
}

-(void)multivaluedInsertButtonTapped:(XLFormRowDescriptor *)formRow
{
    [self deselectFormRow:formRow];
    XLFormSectionDescriptor * multivaluedFormSection = formRow.sectionDescriptor;
    XLFormRowDescriptor * formRowDescriptor = [self formRowFormMultivaluedFormSection:multivaluedFormSection];
    [multivaluedFormSection addFormRow:formRowDescriptor];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.tableView.editing = !self.tableView.editing;
        self.tableView.editing = !self.tableView.editing;
    });
    UITableViewCell<XLFormDescriptorCell> * cell = (UITableViewCell<XLFormDescriptorCell> *)[formRowDescriptor cellForTableView:self.tableView];
    if ([cell formDescriptorCellCanBecomeFirstResponder]){
        [cell formDescriptorCellBecomeFirstResponder];
    }
}

-(void)ensureRowIsVisible:(XLFormRowDescriptor *)inlineRowDescriptor
{
    UITableViewCell<XLFormDescriptorCell> * inlineCell = [inlineRowDescriptor cellForTableView:self.tableView];
    NSIndexPath * indexOfOutOfWindowCell = [self.form indexPathOfFormRow:inlineRowDescriptor];
    [self.tableView scrollToRowAtIndexPath:indexOfOutOfWindowCell atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Helpers

-(void)deselectFormRow:(XLFormRowDescriptor *)formRow
{
    NSIndexPath * indexPath = [self.form indexPathOfFormRow:formRow];
    if (indexPath){
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(void)reloadFormRow:(XLFormRowDescriptor *)formRow
{
    NSIndexPath * indexPath = [self.form indexPathOfFormRow:formRow];
    if (indexPath && self.tableView){
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

-(UITableViewCell<XLFormDescriptorCell> *)updateFormRow:(XLFormRowDescriptor *)formRow
{
    UITableViewCell<XLFormDescriptorCell> * cell = [formRow cellForTableView:self.tableView];
    [self configureCell:cell];
    [cell setNeedsUpdateConstraints];
    [cell setNeedsLayout];
    return cell;
}

-(void)configureCell:(UITableViewCell<XLFormDescriptorCell> *) cell
{
    [cell update];
    [cell.rowDescriptor.cellConfig enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, BOOL * __unused stop) {
        [cell setValue:(value == [NSNull null]) ? nil : value forKeyPath:keyPath];
    }];
    if (cell.rowDescriptor.isDisabled){
        [cell.rowDescriptor.cellConfigIfDisabled enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, id value, BOOL *stop) {
            [cell setValue:(value == [NSNull null]) ? nil : value forKeyPath:keyPath];
        }];
    }
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.form.formSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section >= self.form.formSections.count){
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"" userInfo:nil];
    }
    return [[[self.form.formSections objectAtIndex:section] formRows] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XLFormRowDescriptor * rowDescriptor = [self.form formRowAtIndex:indexPath];
    XLFormBaseCell *cell = [rowDescriptor cellForTableView:self.tableView];
    [self updateFormRow:rowDescriptor];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //用了此方法，autolayout失效，改在cellForRowAtIndexPath方法中去调用updateFormRow
    //XLFormRowDescriptor * rowDescriptor = [self.form formRowAtIndex:indexPath];
    //[self updateFormRow:rowDescriptor];
}


-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    XLFormRowDescriptor *rowDescriptor = [self.form formRowAtIndex:indexPath];
    if (rowDescriptor.isDisabled || !rowDescriptor.sectionDescriptor.isMultivaluedSection){
        return NO;
    }
    UITableViewCell<XLFormDescriptorCell> * baseCell = [rowDescriptor cellForTableView:self.tableView];
    if ([baseCell conformsToProtocol:@protocol(XLFormInlineRowDescriptorCell)] && ((id<XLFormInlineRowDescriptorCell>)baseCell).inlineRowDescriptor){
        return NO;
    }
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    XLFormRowDescriptor *rowDescriptor = [self.form formRowAtIndex:indexPath];
    XLFormSectionDescriptor * section = rowDescriptor.sectionDescriptor;
    if (section.sectionOptions & XLFormSectionOptionCanReorder && section.formRows.count > 1) {
        if (section.sectionInsertMode == XLFormSectionInsertModeButton && section.sectionOptions & XLFormSectionOptionCanInsert){
            if (section.formRows.count <= 2 || rowDescriptor == section.multivaluedAddButton){
                return NO;
            }
        }
        UITableViewCell<XLFormDescriptorCell> * baseCell = [rowDescriptor cellForTableView:self.tableView];
        return !([baseCell conformsToProtocol:@protocol(XLFormInlineRowDescriptorCell)] && ((id<XLFormInlineRowDescriptorCell>)baseCell).inlineRowDescriptor);
    }
    return NO;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    XLFormRowDescriptor * row = [self.form formRowAtIndex:sourceIndexPath];
    XLFormSectionDescriptor * section = row.sectionDescriptor;
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
    [section performSelector:NSSelectorFromString(@"moveRowAtIndexPath:toIndexPath:") withObject:sourceIndexPath withObject:destinationIndexPath];
#pragma GCC diagnostic pop
    // update the accessory view
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.tableView.editing = !self.tableView.editing;
        self.tableView.editing = !self.tableView.editing;
    });
    
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        XLFormRowDescriptor * multivaluedFormRow = [self.form formRowAtIndex:indexPath];
        // end editing
        UIView * firstResponder = [[multivaluedFormRow cellForTableView:self.tableView] findFirstResponder];
        if (firstResponder){
            [self.tableView endEditing:YES];
        }
        [multivaluedFormRow.sectionDescriptor removeFormRowAtIndex:indexPath.row];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.tableView.editing = !self.tableView.editing;
            self.tableView.editing = !self.tableView.editing;
        });
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert){
        
        XLFormSectionDescriptor * multivaluedFormSection = [self.form formSectionAtIndex:indexPath.section];
        if (multivaluedFormSection.sectionInsertMode == XLFormSectionInsertModeButton && multivaluedFormSection.sectionOptions & XLFormSectionOptionCanInsert){
            [self multivaluedInsertButtonTapped:multivaluedFormSection.multivaluedAddButton];
        }
        else{
            XLFormRowDescriptor * formRowDescriptor = [self formRowFormMultivaluedFormSection:multivaluedFormSection];
            [multivaluedFormSection addFormRow:formRowDescriptor];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.tableView.editing = !self.tableView.editing;
                self.tableView.editing = !self.tableView.editing;
            });
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            UITableViewCell<XLFormDescriptorCell> * cell = (UITableViewCell<XLFormDescriptorCell> *)[formRowDescriptor cellForTableView:self.tableView];
            if ([cell formDescriptorCellCanBecomeFirstResponder]){
                [cell formDescriptorCellBecomeFirstResponder];
            }
        }
    }
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    XLFormSectionDescriptor *sectionDescriptor = [self.form.formSections objectAtIndex:section];
    if([sectionDescriptor conformsToProtocol:@protocol(ExpandFormSectionDescriptorDelegate)]){
        return [((XLFormSectionDescriptor<ExpandFormSectionDescriptorDelegate> *)sectionDescriptor) heightForSectionHeader];
    }
    return 0.1;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[self.form.formSections objectAtIndex:section] title];
}

-(NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [[self.form.formSections objectAtIndex:section] footerTitle];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XLFormRowDescriptor *rowDescriptor = [self.form formRowAtIndex:indexPath];
    Class cellClass = [[rowDescriptor cellForTableView:self.tableView] class];
    if ([cellClass respondsToSelector:@selector(formDescriptorCellHeightForRowDescriptor:)]){
        return [cellClass formDescriptorCellHeightForRowDescriptor:rowDescriptor];
    }
    return self.tableView.rowHeight;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XLFormRowDescriptor *rowDescriptor = [self.form formRowAtIndex:indexPath];
    [rowDescriptor cellForTableView:self.tableView];
    CGFloat height = rowDescriptor.height;
    if (height != XLFormUnspecifiedCellHeight){
        return height;
    }
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        return self.tableView.estimatedRowHeight;
    }
    return 44;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XLFormRowDescriptor * row = [self.form formRowAtIndex:indexPath];
    if (row.isDisabled) {
        return;
    }
    UITableViewCell<XLFormDescriptorCell> * cell = (UITableViewCell<XLFormDescriptorCell> *)[row cellForTableView:self.tableView];
    if ([cell respondsToSelector:@selector(formDescriptorCellCanBecomeFirstResponder)] && [cell respondsToSelector:@selector(formDescriptorCellBecomeFirstResponder)]) {
        if (!([cell formDescriptorCellCanBecomeFirstResponder] && [cell formDescriptorCellBecomeFirstResponder])){
            [self.tableView endEditing:YES];
        }
    }
    [self didSelectFormRow:row];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XLFormRowDescriptor * row = [self.form formRowAtIndex:indexPath];
    XLFormSectionDescriptor * section = row.sectionDescriptor;
    if (section.sectionOptions & XLFormSectionOptionCanInsert){
        if (section.formRows.count == indexPath.row + 2){
            if ([[XLFormViewController inlineRowDescriptorTypesForRowDescriptorTypes].allKeys containsObject:row.rowType]){
                UITableViewCell<XLFormDescriptorCell> * cell = [row cellForTableView:self.tableView];
                UIView * firstResponder = [cell findFirstResponder];
                if (firstResponder){
                    return UITableViewCellEditingStyleInsert;
                }
            }
        }
        else if (section.formRows.count == (indexPath.row + 1)){
            return UITableViewCellEditingStyleInsert;
        }
    }
    if (section.sectionOptions & XLFormSectionOptionCanDelete){
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}


- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        return sourceIndexPath;
    }
    XLFormSectionDescriptor * sectionDescriptor = [self.form formSectionAtIndex:sourceIndexPath.section];
    XLFormRowDescriptor * proposedDestination = [sectionDescriptor.formRows objectAtIndex:proposedDestinationIndexPath.row];
    UITableViewCell<XLFormDescriptorCell> * proposedDestinationCell = [proposedDestination cellForTableView:self.tableView];
    if (([proposedDestinationCell conformsToProtocol:@protocol(XLFormInlineRowDescriptorCell)] && ((id<XLFormInlineRowDescriptorCell>)proposedDestinationCell).inlineRowDescriptor) || ([[XLFormViewController inlineRowDescriptorTypesForRowDescriptorTypes].allKeys containsObject:proposedDestinationCell.rowDescriptor.rowType] && [[proposedDestinationCell findFirstResponder] formDescriptorCell] == proposedDestinationCell)) {
        if (sourceIndexPath.row < proposedDestinationIndexPath.row){
            return [NSIndexPath indexPathForRow:proposedDestinationIndexPath.row + 1 inSection:sourceIndexPath.section];
        }
        else{
            return [NSIndexPath indexPathForRow:proposedDestinationIndexPath.row - 1 inSection:sourceIndexPath.section];
        }
    }
    
    if ((sectionDescriptor.sectionInsertMode == XLFormSectionInsertModeButton && sectionDescriptor.sectionOptions & XLFormSectionOptionCanInsert)){
        if (proposedDestinationIndexPath.row == sectionDescriptor.formRows.count - 1){
            return [NSIndexPath indexPathForRow:(sectionDescriptor.formRows.count - 2) inSection:sourceIndexPath.section];
        }
    }
    return proposedDestinationIndexPath;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCellEditingStyle editingStyle = [self tableView:tableView editingStyleForRowAtIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleNone){
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView willBeginReorderingRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell<XLFormDescriptorCell> * cell = [[self.tableView findFirstResponder] formDescriptorCell];
    if ([[self.form indexPathOfFormRow:cell.rowDescriptor] isEqual:indexPath]){
        if ([[XLFormViewController inlineRowDescriptorTypesForRowDescriptorTypes].allKeys containsObject:cell.rowDescriptor.rowType]){
            [self.tableView endEditing:YES];
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.tableView endEditing:YES];
}

#pragma mark - Methods
-(NSArray *)formValidationErrors
{
    return [self.form localValidationErrors:self];
}

@end
