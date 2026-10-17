#import "ViewController.h"
#import "DeviceInfo.h"
#import "CompatibilityChecker.h"
#import "PatchManager.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property (nonatomic, strong) UILabel *deviceModelLabel;
@property (nonatomic, strong) UILabel *osVersionLabel;
@property (nonatomic, strong) UILabel *buildLabel;
@property (nonatomic, strong) UILabel *compatibilityLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIButton *patchButton;

@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) NSMutableArray<UIButton *> *tabButtons;
@property (nonatomic, strong) UIScrollView *homeScrollView;

@property (nonatomic, assign) NSInteger selectedTab;

@end

@implementation ViewController

#pragma mark - Colors

- (UIColor *)backgroundColor {
    return [UIColor colorWithRed:0.025 green:0.035 blue:0.065 alpha:1.0];
}

- (UIColor *)cardColor {
    return [UIColor colorWithRed:0.045 green:0.060 blue:0.100 alpha:1.0];
}

- (UIColor *)purpleColor {
    return [UIColor colorWithRed:0.48 green:0.20 blue:1.0 alpha:1.0];
}

- (UIColor *)greenColor {
    return [UIColor colorWithRed:0.22 green:0.96 blue:0.65 alpha:1.0];
}

- (UIColor *)mutedColor {
    return [UIColor colorWithRed:0.59 green:0.65 blue:0.82 alpha:1.0];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [self backgroundColor];
    self.view.tintColor = [self greenColor];

    self.tabButtons = [NSMutableArray array];

    [self buildLayout];
    [self refreshDeviceInfo];
    [self selectTab:0];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - UI Helpers

- (UILabel *)labelWithText:(NSString *)text
                      size:(CGFloat)size
                     color:(UIColor *)color
                    weight:(UIFontWeight)weight {

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.numberOfLines = 0;

    return label;
}

- (UIView *)card {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [self cardColor];
    view.layer.cornerRadius = 20.0;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.08].CGColor;

    return view;
}

- (UIStackView *)verticalStackWithSpacing:(CGFloat)spacing {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.distribution = UIStackViewDistributionFill;
    stack.spacing = spacing;

    return stack;
}

- (void)pinView:(UIView *)child
         inside:(UIView *)parent
         inset:(CGFloat)inset {

    [NSLayoutConstraint activateConstraints:@[
        [child.topAnchor constraintEqualToAnchor:parent.topAnchor
                                        constant:inset],
        [child.leadingAnchor constraintEqualToAnchor:parent.leadingAnchor
                                            constant:inset],
        [child.trailingAnchor constraintEqualToAnchor:parent.trailingAnchor
                                             constant:-inset],
        [child.bottomAnchor constraintEqualToAnchor:parent.bottomAnchor
                                           constant:-inset]
    ]];
}

#pragma mark - Main Layout

- (void)buildLayout {
    self.contentContainer = [[UIView alloc] init];
    self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainer.backgroundColor = [self backgroundColor];

    [self.view addSubview:self.contentContainer];

    self.tabBar = [self buildBottomBar];
    [self.view addSubview:self.tabBar];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [self.contentContainer.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.contentContainer.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentContainer.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentContainer.bottomAnchor constraintEqualToAnchor:self.tabBar.topAnchor],

        [self.tabBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tabBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tabBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.tabBar.heightAnchor constraintEqualToConstant:84]
    ]];
}

#pragma mark - Bottom Navigation

- (UIView *)buildBottomBar {
    UIView *bar = [[UIView alloc] init];
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    bar.backgroundColor =
        [UIColor colorWithRed:0.035 green:0.045 blue:0.080 alpha:1.0];

    bar.layer.borderWidth = 1.0;
    bar.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.08].CGColor;

    UIStackView *tabs = [[UIStackView alloc] init];
    tabs.translatesAutoresizingMaskIntoConstraints = NO;
    tabs.axis = UILayoutConstraintAxisHorizontal;
    tabs.alignment = UIStackViewAlignmentFill;
    tabs.distribution = UIStackViewDistributionFillEqually;
    tabs.spacing = 0;

    NSArray<NSString *> *symbols = @[@"⌂", @"⚙", @"≡", @"ⓘ"];
    NSArray<NSString *> *titles = @[@"Home", @"Settings", @"Logs", @"About"];

    for (NSInteger index = 0; index < titles.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.tag = index;
        button.backgroundColor = UIColor.clearColor;
        button.accessibilityLabel = titles[index];
        button.accessibilityHint =
            [NSString stringWithFormat:@"Open the %@ tab", titles[index]];

        UIStackView *contents = [[UIStackView alloc] init];
        contents.translatesAutoresizingMaskIntoConstraints = NO;
        contents.axis = UILayoutConstraintAxisVertical;
        contents.alignment = UIStackViewAlignmentCenter;
        contents.distribution = UIStackViewDistributionFill;
        contents.spacing = 3;
        contents.userInteractionEnabled = NO;

        UILabel *icon = [self labelWithText:symbols[index]
                                       size:23
                                      color:[self mutedColor]
                                     weight:UIFontWeightSemibold];

        UILabel *title = [self labelWithText:titles[index]
                                        size:10
                                       color:[self mutedColor]
                                      weight:UIFontWeightMedium];

        title.textAlignment = NSTextAlignmentCenter;

        [contents addArrangedSubview:icon];
        [contents addArrangedSubview:title];

        [button addSubview:contents];

        [NSLayoutConstraint activateConstraints:@[
            [contents.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
            [contents.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
            [contents.leadingAnchor constraintGreaterThanOrEqualToAnchor:button.leadingAnchor constant:2],
            [contents.trailingAnchor constraintLessThanOrEqualToAnchor:button.trailingAnchor constant:-2]
        ]];

        [button addTarget:self
                   action:@selector(tabButtonTapped:)
         forControlEvents:UIControlEventTouchUpInside];

        [tabs addArrangedSubview:button];
        [self.tabButtons addObject:button];
    }

    [bar addSubview:tabs];

    [NSLayoutConstraint activateConstraints:@[
        [tabs.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:8],
        [tabs.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-8],
        [tabs.topAnchor constraintEqualToAnchor:bar.topAnchor constant:4],
        [tabs.bottomAnchor constraintEqualToAnchor:bar.safeAreaLayoutGuide.bottomAnchor constant:-3]
    ]];

    return bar;
}

- (void)tabButtonTapped:(UIButton *)sender {
    [self selectTab:sender.tag];
}

- (void)selectTab:(NSInteger)index {
    if (index < 0 || index >= 4) {
        return;
    }

    self.selectedTab = index;

    NSArray<NSString *> *symbols = @[@"⌂", @"⚙", @"≡", @"ⓘ"];
    NSArray<NSString *> *titles = @[@"Home", @"Settings", @"Logs", @"About"];

    for (NSInteger i = 0; i < self.tabButtons.count; i++) {
        UIButton *button = self.tabButtons[i];
        BOOL selected = (i == index);

        UIColor *color = selected
            ? [self greenColor]
            : [self mutedColor];

        button.accessibilityTraits = selected
            ? UIAccessibilityTraitButton | UIAccessibilityTraitSelected
            : UIAccessibilityTraitButton;

        for (UIView *subview in button.subviews) {
            if (![subview isKindOfClass:[UIStackView class]]) {
                continue;
            }

            UIStackView *stack = (UIStackView *)subview;

            if (stack.arrangedSubviews.count >= 2) {
                UILabel *icon = (UILabel *)stack.arrangedSubviews[0];
                UILabel *title = (UILabel *)stack.arrangedSubviews[1];

                icon.text = symbols[i];
                icon.textColor = color;
                title.text = titles[i];
                title.textColor = color;
                title.font = [UIFont systemFontOfSize:10
                                                weight:selected
                                                    ? UIFontWeightBold
                                                    : UIFontWeightMedium];
            }
        }
    }

    [self showScreen:index];
}

#pragma mark - Screen Routing

- (void)showScreen:(NSInteger)index {
    for (UIView *view in self.contentContainer.subviews) {
        [view removeFromSuperview];
    }

    self.homeScrollView = nil;

    switch (index) {
        case 0:
            [self showHome];
            break;

        case 1:
            [self showSettings];
            break;

        case 2:
            [self showLogs];
            break;

        case 3:
            [self showAbout];
            break;

        default:
            break;
    }
}

#pragma mark - Home Screen

- (void)showHome {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.showsVerticalScrollIndicator = NO;

    self.homeScrollView = scroll;

    [self.contentContainer addSubview:scroll];

    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;

    [scroll addSubview:content];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor],

        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor]
    ]];

    UIStackView *stack = [self verticalStackWithSpacing:18];
    [content addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:content.topAnchor constant:20],
        [stack.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18],
        [stack.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-18],
        [stack.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-24]
    ]];

    [stack addArrangedSubview:[self buildHeader]];
    [stack addArrangedSubview:[self buildDeviceCard]];
    [stack addArrangedSubview:[self buildCompatibilityCard]];
    [stack addArrangedSubview:[self buildStatusCard]];
    [stack addArrangedSubview:[self buildPatchButton]];
    [stack addArrangedSubview:[self buildInformationCards]];
    [stack addArrangedSubview:[self buildFooter]];
}

- (UIView *)buildHeader {
    UIStackView *header = [[UIStackView alloc] init];
    header.translatesAutoresizingMaskIntoConstraints = NO;
    header.axis = UILayoutConstraintAxisHorizontal;
    header.alignment = UIStackViewAlignmentCenter;
    header.spacing = 12;

    UIView *logo = [[UIView alloc] init];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.backgroundColor =
        [UIColor colorWithRed:0.20 green:0.09 blue:0.40 alpha:1.0];
    logo.layer.cornerRadius = 16;
    logo.layer.borderWidth = 1;
    logo.layer.borderColor = [self purpleColor].CGColor;

    UILabel *logoLabel = [self labelWithText:@"↯"
                                        size:32
                                       color:[self greenColor]
                                      weight:UIFontWeightHeavy];
    logoLabel.textAlignment = NSTextAlignmentCenter;

    [logo addSubview:logoLabel];

    [NSLayoutConstraint activateConstraints:@[
        [logo.widthAnchor constraintEqualToConstant:54],
        [logo.heightAnchor constraintEqualToConstant:54],
        [logoLabel.centerXAnchor constraintEqualToAnchor:logo.centerXAnchor],
        [logoLabel.centerYAnchor constraintEqualToAnchor:logo.centerYAnchor]
    ]];

    UIStackView *branding = [self verticalStackWithSpacing:3];

    [branding addArrangedSubview:
        [self labelWithText:@"hurr1c4ne"
                       size:27
                      color:UIColor.whiteColor
                     weight:UIFontWeightHeavy]];

    [branding addArrangedSubview:
        [self labelWithText:@"iOS / iPadOS RESEARCH"
                       size:10
                      color:[self mutedColor]
                     weight:UIFontWeightBold]];

    UIView *spacer = [[UIView alloc] init];

    UIStackView *mode = [self verticalStackWithSpacing:4];
    mode.alignment = UIStackViewAlignmentTrailing;

    [mode addArrangedSubview:
        [self labelWithText:@"● RESEARCH"
                       size:10
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    [mode addArrangedSubview:
        [self labelWithText:@"MODE"
                       size:10
                      color:[self mutedColor]
                     weight:UIFontWeightMedium]];

    [header addArrangedSubview:logo];
    [header addArrangedSubview:branding];
    [header addArrangedSubview:spacer];
    [header addArrangedSubview:mode];

    return header;
}

#pragma mark - Device Card

- (UIView *)buildDeviceCard {
    UIView *card = [self card];
    UIStackView *stack = [self verticalStackWithSpacing:13];

    [card addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];

    [stack addArrangedSubview:
        [self labelWithText:@"▣  DEVICE INFORMATION"
                       size:12
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    UIView *divider = [[UIView alloc] init];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    divider.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];

    [divider.heightAnchor constraintEqualToConstant:1].active = YES;
    [stack addArrangedSubview:divider];

    UIStackView *columns = [[UIStackView alloc] init];
    columns.translatesAutoresizingMaskIntoConstraints = NO;
    columns.axis = UILayoutConstraintAxisHorizontal;
    columns.alignment = UIStackViewAlignmentTop;
    columns.distribution = UIStackViewDistributionFillEqually;
    columns.spacing = 8;

    UIStackView *model = [self verticalStackWithSpacing:6];
    UIStackView *os = [self verticalStackWithSpacing:6];
    UIStackView *build = [self verticalStackWithSpacing:6];

    [model addArrangedSubview:
        [self labelWithText:@"MODEL" size:9 color:[self mutedColor]
                     weight:UIFontWeightBold]];

    self.deviceModelLabel =
        [self labelWithText:@"Detecting…" size:13 color:UIColor.whiteColor
                     weight:UIFontWeightBold];

    self.deviceModelLabel.adjustsFontSizeToFitWidth = YES;
    self.deviceModelLabel.minimumScaleFactor = 0.65;

    [model addArrangedSubview:self.deviceModelLabel];

    [os addArrangedSubview:
        [self labelWithText:@"iOS VERSION" size:9 color:[self mutedColor]
                     weight:UIFontWeightBold]];

    self.osVersionLabel =
        [self labelWithText:@"Detecting…" size:13 color:UIColor.whiteColor
                     weight:UIFontWeightBold];

    [os addArrangedSubview:self.osVersionLabel];

    [build addArrangedSubview:
        [self labelWithText:@"BUILD" size:9 color:[self mutedColor]
                     weight:UIFontWeightBold]];

    self.buildLabel =
        [self labelWithText:@"Detecting…" size:12 color:UIColor.whiteColor
                     weight:UIFontWeightMedium];

    self.buildLabel.adjustsFontSizeToFitWidth = YES;
    self.buildLabel.minimumScaleFactor = 0.6;

    [build addArrangedSubview:self.buildLabel];

    [columns addArrangedSubview:model];
    [columns addArrangedSubview:os];
    [columns addArrangedSubview:build];

    [stack addArrangedSubview:columns];

    return card;
}

#pragma mark - Compatibility Card

- (UIView *)buildCompatibilityCard {
    UIView *card = [self card];
    UIStackView *stack = [self verticalStackWithSpacing:12];

    [card addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];

    [stack addArrangedSubview:
        [self labelWithText:@"✓  COMPATIBILITY"
                       size:12
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    self.compatibilityLabel =
        [self labelWithText:@"Checking operating system…"
                       size:14
                      color:UIColor.whiteColor
                     weight:UIFontWeightSemibold];

    [stack addArrangedSubview:self.compatibilityLabel];

    [stack addArrangedSubview:
        [self labelWithText:@"OS compatibility does not confirm exploit availability."
                       size:11
                      color:[self mutedColor]
                     weight:UIFontWeightRegular]];

    return card;
}

#pragma mark - Status Card

- (UIView *)buildStatusCard {
    UIView *card = [self card];
    UIStackView *stack = [self verticalStackWithSpacing:10];

    [card addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:card.topAnchor constant:16],
        [stack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [stack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
        [stack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-16]
    ]];

    [stack addArrangedSubview:
        [self labelWithText:@"∿  SYSTEM STATUS"
                       size:12
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    [stack addArrangedSubview:
        [self labelWithText:@"Research scaffold ready"
                       size:15
                      color:UIColor.whiteColor
                     weight:UIFontWeightBold]];

    self.statusLabel =
        [self labelWithText:@"No exploit backend is integrated."
                       size:12
                      color:[self mutedColor]
                     weight:UIFontWeightRegular];

    [stack addArrangedSubview:self.statusLabel];

    return card;
}

#pragma mark - Patch Button

- (UIView *)buildPatchButton {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;

    self.patchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.patchButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.patchButton.backgroundColor = [self purpleColor];
    self.patchButton.layer.cornerRadius = 18;
    self.patchButton.layer.borderWidth = 1;
    self.patchButton.layer.borderColor =
        [UIColor colorWithRed:0.68 green:0.48 blue:1 alpha:1].CGColor;

    [self.patchButton setTitle:@"↯   PatchMe   ›"
                      forState:UIControlStateNormal];

    [self.patchButton setTitleColor:UIColor.whiteColor
                           forState:UIControlStateNormal];

    self.patchButton.titleLabel.font =
        [UIFont systemFontOfSize:22 weight:UIFontWeightHeavy];

    [self.patchButton addTarget:self
                         action:@selector(patchTapped)
               forControlEvents:UIControlEventTouchUpInside];

    [container addSubview:self.patchButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.patchButton.topAnchor constraintEqualToAnchor:container.topAnchor],
        [self.patchButton.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [self.patchButton.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [self.patchButton.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],
        [self.patchButton.heightAnchor constraintEqualToConstant:70]
    ]];

    return container;
}

#pragma mark - Information Cards

- (UIView *)buildInformationCards {
    UIStackView *row = [[UIStackView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentFill;
    row.distribution = UIStackViewDistributionFillEqually;
    row.spacing = 12;

    UIView *about = [self card];
    UIView *notice = [self card];

    UIStackView *aboutStack = [self verticalStackWithSpacing:10];
    UIStackView *noticeStack = [self verticalStackWithSpacing:10];

    [about addSubview:aboutStack];
    [notice addSubview:noticeStack];

    [self pinView:aboutStack inside:about inset:12];
    [self pinView:noticeStack inside:notice inset:12];

    [aboutStack addArrangedSubview:
        [self labelWithText:@"ⓘ  ABOUT"
                       size:11
                      color:[self mutedColor]
                     weight:UIFontWeightBold]];

    [aboutStack addArrangedSubview:
        [self labelWithText:@"An iOS research project requiring compatible system capabilities."
                       size:12
                      color:UIColor.whiteColor
                     weight:UIFontWeightRegular]];

    [noticeStack addArrangedSubview:
        [self labelWithText:@"⚠  IMPORTANT"
                       size:11
                      color:[self mutedColor]
                     weight:UIFontWeightBold]];

    [noticeStack addArrangedSubview:
        [self labelWithText:@"Research scaffold only. No jailbreak capability is implied."
                       size:12
                      color:UIColor.whiteColor
                     weight:UIFontWeightRegular]];

    [row addArrangedSubview:about];
    [row addArrangedSubview:notice];

    return row;
}

#pragma mark - Footer

- (UIView *)buildFooter {
    UILabel *footer =
        [self labelWithText:@"hurr1c4ne  •  RESEARCH BUILD  •  v0.1.0"
                       size:10
                      color:[self mutedColor]
                     weight:UIFontWeightMedium];

    footer.textAlignment = NSTextAlignmentCenter;

    return footer;
}

#pragma mark - Settings Screen

- (void)showSettings {
    UIStackView *stack = [self verticalStackWithSpacing:18];
    [self.contentContainer addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor constant:28],
        [stack.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor constant:-20]
    ]];

    [stack addArrangedSubview:
        [self labelWithText:@"Settings"
                       size:30
                      color:UIColor.whiteColor
                     weight:UIFontWeightHeavy]];

    UIView *card = [self card];
    UIStackView *items = [self verticalStackWithSpacing:16];

    [card addSubview:items];
    [self pinView:items inside:card inset:18];

    [items addArrangedSubview:
        [self labelWithText:@"BOOTSTRAP"
                       size:11
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    [items addArrangedSubview:
        [self labelWithText:@"Procursus · Rootless"
                       size:16
                      color:UIColor.whiteColor
                     weight:UIFontWeightSemibold]];

    [items addArrangedSubview:
        [self labelWithText:@"Bootstrap installation has not been verified."
                       size:12
                      color:[self mutedColor]
                     weight:UIFontWeightRegular]];

    [items addArrangedSubview:
        [self labelWithText:@"TARGET VERSIONS"
                       size:11
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    [items addArrangedSubview:
        [self labelWithText:@"iOS 26.0 – 27.0.1"
                       size:15
                      color:UIColor.whiteColor
                     weight:UIFontWeightSemibold]];

    [stack addArrangedSubview:card];

    [stack addArrangedSubview:
        [self labelWithText:@"This screen reports project configuration. It does not change system security settings."
                       size:12
                      color:[self mutedColor]
                     weight:UIFontWeightRegular]];
}

#pragma mark - Logs Screen

- (void)showLogs {
    UIStackView *stack = [self verticalStackWithSpacing:16];
    [self.contentContainer addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor constant:28],
        [stack.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor constant:-20]
    ]];

    [stack addArrangedSubview:
        [self labelWithText:@"Logs"
                       size:30
                      color:UIColor.whiteColor
                     weight:UIFontWeightHeavy]];

    UIView *card = [self card];
    UIStackView *logItems = [self verticalStackWithSpacing:12];

    [card addSubview:logItems];
    [self pinView:logItems inside:card inset:16];

    [logItems addArrangedSubview:
        [self labelWithText:@"[INFO] hurr1c4ne interface initialized"
                       size:12
                      color:[self greenColor]
                     weight:UIFontWeightMedium]];

    [logItems addArrangedSubview:
        [self labelWithText:@"[INFO] Device information loaded"
                       size:12
                      color:UIColor.whiteColor
                     weight:UIFontWeightRegular]];

    [logItems addArrangedSubview:
        [self labelWithText:@"[INFO] Rootless Procursus integration planned"
                       size:12
                      color:UIColor.whiteColor
                     weight:UIFontWeightRegular]];

    [logItems addArrangedSubview:
        [self labelWithText:@"[NOTICE] Bootstrap installation not verified"
                       size:12
                      color:[self mutedColor]
                     weight:UIFontWeightRegular]];

    [logItems addArrangedSubview:
        [self labelWithText:@"[NOTICE] No exploit backend integrated"
                       size:12
                      color:[self mutedColor]
                     weight:UIFontWeightRegular]];

    [stack addArrangedSubview:card];
}

#pragma mark - About Screen

- (void)showAbout {
    UIStackView *stack = [self verticalStackWithSpacing:18];
    [self.contentContainer addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor constant:28],
        [stack.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor constant:-20]
    ]];

    [stack addArrangedSubview:
        [self labelWithText:@"About hurr1c4ne"
                       size:29
                      color:UIColor.whiteColor
                     weight:UIFontWeightHeavy]];

    UIView *card = [self card];
    UIStackView *details = [self verticalStackWithSpacing:12];

    [card addSubview:details];
    [self pinView:details inside:card inset:18];

    [details addArrangedSubview:
        [self labelWithText:@"VERSION 0.1.0"
                       size:12
                      color:[self greenColor]
                     weight:UIFontWeightBold]];

    [details addArrangedSubview:
        [self labelWithText:@"An Objective-C iOS research project."
                       size:15
                      color:UIColor.whiteColor
                     weight:UIFontWeightSemibold]];

    [details addArrangedSubview:
        [self labelWithText:@"Target range: iOS 26.0 through 27.0.1."
                       size:13
                      color:[self mutedColor]
                     weight:UIFontWeightRegular]];

    [details addArrangedSubview:
        [self labelWithText:@"The Procursus rootless bootstrap is a planned integration. This build does not claim that a jailbreak is installed."
                       size:13
                      color:UIColor.whiteColor
                     weight:UIFontWeightRegular]];

    [stack addArrangedSubview:card];
}

#pragma mark - Device Information

- (void)refreshDeviceInfo {
    DeviceInfo *info = [DeviceInfo currentDeviceInfo];

    NSString *model = info.modelIdentifier.length
        ? info.modelIdentifier
        : @"Unknown device";

    NSString *osVersion = info.osVersion.length
        ? info.osVersion
        : @"Unknown";

    NSString *build = info.osBuild.length
        ? info.osBuild
        : @"Unknown";

    self.deviceModelLabel.text = model;
    self.osVersionLabel.text = osVersion;
    self.buildLabel.text = build;

    NSString *summary =
        [CompatibilityChecker summaryForOSVersion:osVersion];

    self.compatibilityLabel.text = summary.length
        ? summary
        : @"Compatibility information unavailable.";
}

#pragma mark - Patch Action

- (void)patchTapped {
    self.patchButton.enabled = NO;
    self.patchButton.alpha = 0.65;

    self.statusLabel.text = @"Evaluating available capabilities…";

    [[PatchManager sharedManager]
        evaluateWithCompletion:^(NSString *message) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.statusLabel.text = message.length
                    ? message
                    : @"No additional capabilities reported.";

                self.patchButton.enabled = YES;
                self.patchButton.alpha = 1.0;
            });
        }];
}

@end
