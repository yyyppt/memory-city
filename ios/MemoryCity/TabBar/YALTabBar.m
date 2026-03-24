//
//  YALTabBar.m
//  MemoryCity
//
//  Created by yyyyy on 2026/3/11.
//

#import "YALTabBar.h"
#import <Masonry/Masonry.h>

@implementation YALTabBar

- (instancetype)init {
  self = [super init];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInit];
  }
  return self;
}

- (void)commonInit {
  if (self.centerButton) {
    return;
  }

  CGFloat diameter = 64.0;
  self.clipsToBounds = NO;

  self.centerButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.centerButton.layer.cornerRadius = diameter / 2.0;

  UIColor *highlightColor = [UIColor colorWithRed:1 green:0.6 blue:0.2 alpha:1];
  self.centerButton.backgroundColor = highlightColor;
  self.centerButton.layer.borderColor = [UIColor whiteColor].CGColor;
  self.centerButton.layer.borderWidth = 4.0;
  self.centerButton.layer.shadowColor = highlightColor.CGColor;
  self.centerButton.layer.shadowOpacity = 0.8;
  self.centerButton.layer.shadowRadius = 12.0;
  self.centerButton.layer.shadowOffset = CGSizeZero;

  [self addSubview:self.centerButton];

  [self.centerButton mas_makeConstraints:^(MASConstraintMaker *make) {
    make.centerX.equalTo(self);
    make.centerY.equalTo(self.mas_top).offset(15.0);
    make.width.height.mas_equalTo(diameter);
  }];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
  if (self.hidden == NO) {
    CGPoint converted = [self convertPoint:point toView:self.centerButton];
    if ([self.centerButton pointInside:converted withEvent:event]) {
      return self.centerButton;
    }
  }

  return [super hitTest:point withEvent:event];
}

@end
