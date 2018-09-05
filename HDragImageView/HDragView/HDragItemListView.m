//
//  HDragItemListView.m
//  HDragImageDemo
//
//  Created by 黄江龙 on 2018/9/5.
//  Copyright © 2018年 huangjianglong. All rights reserved.
//

#import "HDragItemListView.h"
#import "UIButton+Ex.h"
#import "UIView+Ex.h"

#define SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT   [[UIScreen mainScreen] bounds].size.height

@interface HDragItemListView()

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) CGSize itemSize;
/**
 *  需要移动的矩阵
 */
@property (nonatomic, assign) CGRect moveFinalRect;
@property (nonatomic, assign) CGPoint oriCenter;

@property (nonatomic, strong) UIView *deleteView;
@end

@implementation HDragItemListView

- (NSMutableArray *)itemArray{
    return [self.items mutableCopy];
}

- (NSMutableArray *)items
{
    if (!_items) {
        _items = [[NSMutableArray alloc] init];
    }
    return _items;
}

- (CGFloat)itemListH
{
    if (self.items.count <= 0) return 0;
    return CGRectGetMaxY([self.items.lastObject frame]) + _itemMargin;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}


#pragma mark - 初始化
- (void)setup
{
    _itemMargin = 10;
    _itemListCols = 3;
    _scaleItemInSort = 1;
    _isFitItemListH = YES;
    _showDeleteView = YES;
    _deleteViewHeight = 50.0;
    _maxItem = 9;
    CGFloat width = (self.frame.size.width - ((_itemListCols + 1) * _itemMargin)) / _itemListCols;
    _itemSize = CGSizeMake(width, width);
    self.clipsToBounds = YES;
}

- (void)setScaleItemInSort:(CGFloat)scaleItemInSort
{
    if (_scaleItemInSort < 1) {
        @throw [NSException exceptionWithName:@"YZError" reason:@"(scaleTagInSort)缩放比例必须大于1" userInfo:nil];
    }
    _scaleItemInSort = scaleItemInSort;
}

#pragma mark - 操作标签方法
// 添加多个标签
- (void)addItems:(NSArray<HDragItem *> *)items
{
    if (self.frame.size.width == 0) {
        @throw [NSException exceptionWithName:@"YZError" reason:@"先设置标签列表的frame" userInfo:nil];
    }
    
    for (HDragItem *item in items) {
        [self addItem:item];
    }
}

// 添加标签
- (void)addItem:(HDragItem *)item
{
    
    //移除“添加”item
    if (self.items.count && self.items.count == _maxItem) {
        HDragItem *last = [self.items lastObject];
        [self.items removeObject:last];
        [last removeFromSuperview];
    }
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickItem:)];
    [item addGestureRecognizer:tap];
    
    if (_isSort && !item.isAdd) {
        // 添加拖动手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [item addGestureRecognizer:pan];
    }
    [self addSubview:item];
    
    NSInteger tag = self.items.count;
    HDragItem *addItem = nil;
    if (self.items.count) {
        HDragItem *lastItem = [self.items lastObject];
        if (lastItem.isAdd) {
            addItem = lastItem;
            tag = lastItem.tag;
            lastItem.tag = tag +1;
        }
    }
    
    item.tag = tag;
    
    // 保存到数组
    if (addItem) {
        [self.items insertObject:item atIndex:self.items.count - 1];
    }
    else {
        [self.items addObject:item];
    }
    
    // 设置按钮的位置
    [self updateItemFrame:item.tag extreMargin:YES];
    if (addItem) {
        [self updateItemFrame:addItem.tag extreMargin:YES];
    }
    
    // 更新自己的高度
    if (_isFitItemListH) {
        CGRect frame = self.frame;
        frame.size.height = self.itemListH;
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = frame;
        }];
    }
}

// 点击标签
- (void)clickItem:(UITapGestureRecognizer *)tap
{
    [self dismissKeyBord];
    if (_clickItemBlock) {
        _clickItemBlock((HDragItem *)tap.view);
    }
}

// 拖动标签
- (void)pan:(UIPanGestureRecognizer *)pan
{
    [self dismissKeyBord];
    
    //坐标转换
    CGRect rect = [self.superview convertRect:self.frame toView:[UIApplication sharedApplication].keyWindow];
    
    // 获取偏移量
    CGPoint transP = [pan translationInView:self];
    
    HDragItem *tagButton = (HDragItem *)pan.view;
    
    // 开始
    if (pan.state == UIGestureRecognizerStateBegan) {
        _oriCenter = tagButton.center;
        [UIView animateWithDuration:-.25 animations:^{
            tagButton.transform = CGAffineTransformMakeScale(self->_scaleItemInSort, self->_scaleItemInSort);
        }];
        
        if (self.showDeleteView) {
            [self showDeleteViewAnimation];
        }
        
        [[UIApplication sharedApplication].keyWindow addSubview:tagButton];

        tagButton.top = rect.origin.y + tagButton.top;
        tagButton.left = rect.origin.x + tagButton.left;
    }
    
    CGPoint center = tagButton.center;
    center.x += transP.x;
    center.y += transP.y;
    tagButton.center = center;
    
    // 改变
    if (pan.state == UIGestureRecognizerStateChanged) {
        
        // 获取当前按钮中心点在哪个按钮上
        HDragItem *otherButton = [self buttonCenterInButtons:tagButton];
        
        if (otherButton && !otherButton.isAdd) { // 插入到当前按钮的位置
            // 获取插入的角标
            NSInteger i = otherButton.tag;
            
            // 获取当前角标
            NSInteger curI = tagButton.tag;
            
            _moveFinalRect = otherButton.frame;
            
            // 排序
            // 移除之前的按钮
            [self.items removeObject:tagButton];
            [self.items insertObject:tagButton atIndex:i];
            
            // 更新tag
            [self updateItem];
            
            if (curI > i) { // 往前插
                
                // 更新之后标签frame
                [UIView animateWithDuration:0.25 animations:^{
                    [self updateLaterItemButtonFrame:i + 1];
                }];
                
            } else { // 往后插
                
                // 更新之前标签frame
                [UIView animateWithDuration:0.25 animations:^{
                    [self updateBeforeTagButtonFrame:i];
                }];
            }
        }
        
        if (self.showDeleteView) {
            if (tagButton.frame.origin.y + tagButton.frame.size.height > SCREEN_HEIGHT - _deleteViewHeight) {
                [self setDeleteViewDeleteState];
            }
            else {
                [self setDeleteViewNormalState];
            }
        }
        
    }
    
    // 结束
    if (pan.state == UIGestureRecognizerStateEnded) {
        BOOL deleted = NO;
        if (self.showDeleteView) {
            [self hiddenDeleteViewAnimation];
            if (tagButton.frame.origin.y + tagButton.frame.size.height > SCREEN_HEIGHT - _deleteViewHeight) {
                deleted = YES;
                [self deleteItem:tagButton];
            }
        }
        
        [UIView animateWithDuration:0.25 animations:^{
            tagButton.transform = CGAffineTransformIdentity;
            if (self->_moveFinalRect.size.width <= 0) {
                tagButton.center = self->_oriCenter;
            } else {
                tagButton.frame = self->_moveFinalRect;
            }
            tagButton.left = tagButton.left + rect.origin.x;
            tagButton.top = tagButton.top + rect.origin.y;
        } completion:^(BOOL finished) {
            self->_moveFinalRect = CGRectZero;
            if (!deleted) {
                [self addSubview:tagButton];
                tagButton.left = tagButton.left - rect.origin.x;
                tagButton.top = tagButton.top - rect.origin.y;
            }
        }];
        
    }
    
    [pan setTranslation:CGPointZero inView:self];
}

// 看下当前按钮中心点在哪个按钮上
- (HDragItem *)buttonCenterInButtons:(HDragItem *)curItem
{
    for (HDragItem *button in self.items) {
        if (curItem == button) continue;
        //坐标转换
        CGRect rect = [self.superview convertRect:self.frame toView:[UIApplication sharedApplication].keyWindow];
        CGRect frame = CGRectMake(button.x + rect.origin.x, button.y + rect.origin.y, button.width, button.height);
        if (CGRectContainsPoint(frame, curItem.center)) {
            return button;
        }
    }
    return nil;
}


// 删除Itme
- (void)deleteItem:(HDragItem *)item
{
    [item removeFromSuperview];
    
    // 移除数组
    [self.items removeObject:item];
    
    // 更新item
    [self updateItem];
    
    // 更新后面item的frame
    [UIView animateWithDuration:0.25 animations:^{
        [self updateLaterItemButtonFrame:item.tag];
    }];
    
    // 更新自己的frame
    if (_isFitItemListH) {
        CGRect frame = self.frame;
        frame.size.height = self.itemListH;
        [UIView animateWithDuration:0.25 animations:^{
            self.frame = frame;
        }];
    }
    
    if (_deleteItemBlock) {
        _deleteItemBlock(nil);
    }
}

// 更新item
- (void)updateItem
{
    NSInteger count = self.items.count;
    for (int i = 0; i < count; i++) {
        UIButton *tagButton = self.items[i];
        tagButton.tag = i;
    }
}

// 更新之前按钮
- (void)updateBeforeTagButtonFrame:(NSInteger)beforeI
{
    for (int i = 0; i < beforeI; i++) {
        // 更新按钮
        [self updateItemFrame:i extreMargin:NO];
    }
}

// 更新以后按钮
- (void)updateLaterItemButtonFrame:(NSInteger)laterI
{
    NSInteger count = self.items.count;
    
    for (NSInteger i = laterI; i < count; i++) {
        // 更新按钮
        [self updateItemFrame:i extreMargin:NO];
    }
}

- (void)updateItemFrame:(NSInteger)i extreMargin:(BOOL)extreMargin
{
    // 获取上一个按钮
    NSInteger preI = i - 1;
    
    // 定义上一个按钮
    HDragItem *preItem;
    
    // 过滤上一个角标
    if (preI >= 0) {
        preItem = self.items[preI];
    }
    
    // 获取当前按钮
    HDragItem *tagItem = self.items[i];
    
    [self setupItemButtonRegularFrame:tagItem];
    
}

// 计算标签按钮frame（按规律排布）
- (void)setupItemButtonRegularFrame:(HDragItem *)tagItem
{
    // 获取角标
    NSInteger i = tagItem.tag;
    NSInteger col = i % _itemListCols;
    NSInteger row = i / _itemListCols;
    CGFloat btnW = _itemSize.width;
    CGFloat btnH = _itemSize.height;
//    NSInteger margin = (self.bounds.size.width - _itemListCols * btnW - 2 * _itemMargin) / (_itemListCols - 1);
    CGFloat btnX = col * (btnW + _itemMargin) + _itemMargin;
    CGFloat btnY = row * (btnH + _itemMargin);
    tagItem.frame = CGRectMake(btnX, btnY, btnW, btnH);
}

#pragma mark - 底部删除 视图
- (UIView *)deleteView{
    if (!_deleteView) {
        _deleteView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, _deleteViewHeight)];
        _deleteView.backgroundColor = [UIColor redColor];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = 201809;
        [button setImage:[UIImage imageNamed:@"wc_drag_delete"] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:@"wc_drag_delete_activate"] forState:UIControlStateSelected];
        [button setTitle:@"拖到此处删除" forState:UIControlStateNormal];
        [button setTitle:@"松手即可删除" forState:UIControlStateSelected];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        [button layoutButtonWithEdgeInsetsStyle:TYButtonEdgeInsetsStyleTop imageTitleSpace:30];
        [_deleteView addSubview:button];
        [button sizeToFit];
        CGRect frame = button.frame;
        frame.origin.x = (_deleteView.frame.size.width - frame.size.width) / 2;
        frame.origin.y = (_deleteViewHeight - frame.size.height) / 2 + 5;
        button.frame = frame;
        
        [[UIApplication sharedApplication].keyWindow addSubview:_deleteView];
    }
    return _deleteView;
}

- (void)showDeleteViewAnimation{
    self.deleteView.hidden = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.deleteView.transform = CGAffineTransformTranslate( self.deleteView.transform, 0, - self->_deleteViewHeight);
        
    } completion:^(BOOL finished) {
        
    }];
}

- (void)hiddenDeleteViewAnimation{
    [UIView animateWithDuration:0.25 animations:^{
        self.deleteView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)setDeleteViewDeleteState{
    UIButton *button = (UIButton *)[_deleteView viewWithTag:201809];
    button.selected = YES;
}

- (void)setDeleteViewNormalState{
    UIButton *button = (UIButton *)[_deleteView viewWithTag:201809];
    button.selected = NO;
}

- (void)dismissKeyBord{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

@end
