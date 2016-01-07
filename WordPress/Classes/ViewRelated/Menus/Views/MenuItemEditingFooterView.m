#import "MenuItemEditingFooterView.h"
#import "MenusActionButton.h"
#import "WPStyleGuide.h"

@interface MenuItemEditingFooterView ()

@property (nonatomic, strong) IBOutlet MenusActionButton *cancelButton;
@property (nonatomic, strong) IBOutlet MenusActionButton *trashButton;
@property (nonatomic, strong) IBOutlet MenusActionButton *saveButton;

@end

@implementation MenuItemEditingFooterView

- (void)awakeFromNib
{
    [super awakeFromNib];

    {
        MenusActionButton *button = self.cancelButton;
        [button setTitle:NSLocalizedString(@"Cancel", @"") forState:UIControlStateNormal];
        [button addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    {
        MenusActionButton *button = self.trashButton;
        button.tintColor = [WPStyleGuide errorRed];
        [button setImage:[button templatedIconImageNamed:@"icon-menus-trash"] forState:UIControlStateNormal];
    }
    {
        MenusActionButton *button = self.saveButton;
        button.fillColor = [WPStyleGuide mediumBlue];
        [button setTitle:NSLocalizedString(@"OK", @"") forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)drawRect:(CGRect)rect
{    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    CGContextSetLineWidth(context, 2.0);
    
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context, rect.size.width, 0);
    
    CGContextStrokePath(context);
}

#pragma mark - buttons

- (void)cancelButtonPressed
{
    [self.delegate editingFooterViewDidSelectCancel:self];
}

@end
