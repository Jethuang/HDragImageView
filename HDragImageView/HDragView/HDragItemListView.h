//
//  HDragItemListView.h
//  HDragImageDemo
//
//  Created by 黄江龙 on 2018/9/5.
//  Copyright © 2018年 huangjianglong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HDragItem.h"

@interface HDragItemListView : UIView
/**
 *  item间距,和距离左，上间距,默认10
 */
@property (nonatomic, assign) CGFloat itemMargin;

/**
 *  是否需要自定义ItemList高度，默认为Yes
 */
@property (nonatomic, assign) BOOL isFitItemListH;

/**
 *  是否需要排序功能
 */
@property (nonatomic, assign) BOOL isSort;

/**
 *  在排序的时候，放大标签的比例，必须大于1
 */
@property (nonatomic, assign) CGFloat scaleItemInSort;

/******列表总列数 默认3列******/
/**
 *  item间距会自动计算
 */
@property (nonatomic, assign) NSInteger itemListCols;

/**
 *  显示拖拽到底部出现删除 默认yes
 */
@property (nonatomic, assign) BOOL showDeleteView;
/**
 *  DragItemBottomView 的高度 默认50
 */
@property (nonatomic, assign) CGFloat deleteViewHeight;

/**
 *  item列表的高度
 */
@property (nonatomic, assign) CGFloat itemListH;

/**
 *  获取所有item
 */
@property (nonatomic, strong, readonly) NSMutableArray *itemArray;
/**
 *  item 最多个数 默认9个
 */
@property (nonatomic, assign) int maxItem;

/**
 *  添加item
 * */
- (void)addItem:(HDragItem *)item;

/**
 *  添加多个item
 */
- (void)addItems:(NSArray<HDragItem *> * )items;

/**
 *  删除item
 */
- (void)deleteItem:(HDragItem *)item;

/**
 *  点击标签，执行Block
 */
@property (nonatomic, strong) void(^clickItemBlock)(HDragItem *item);

/**
 *  移除回调
 */
@property (nonatomic, strong) void(^deleteItemBlock)(HDragItem *item);

@end
