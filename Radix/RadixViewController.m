#import "RadixViewController.h"

@interface RadixViewController ()

@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *packageCountLabel;
@property (nonatomic, strong) UIButton *refreshButton;
@property (nonatomic, strong) UIStackView *contentStack;

@end

@implementation RadixViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Radix";
    self.view.backgroundColor = [UIColor colorWithRed:0.055
                                                 green:0.065
                                                  blue:0.10
                                                 alpha:1.0];

    [self buildInterface];
}

- (void)buildInterface {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.view addSubview:scrollView];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor
         constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor
         constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor
         constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor
         constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    self.contentStack = [[UIStackView alloc] init];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.spacing = 18;
    self.contentStack.alignment = UIStackViewAlignmentFill;
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;

    [scrollView addSubview:self.contentStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentStack.topAnchor
         constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor
         constant:24],
        [self.contentStack.leadingAnchor
         constraintEqualToAnchor:scrollView.frameLayoutGuide.leadingAnchor
         constant:20],
        [self.contentStack.trailingAnchor
         constraintEqualToAnchor:scrollView.frameLayoutGuide.trailingAnchor
         constant:-20],
        [self.contentStack.bottomAnchor
         constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor
         constant:-28]
    ]];

    UILabel *logoLabel = [[UILabel alloc] init];
    logoLabel.text = @"Radix";
    logoLabel.font = [UIFont systemFontOfSize:38
                                       weight:UIFontWeightBold];
    logoLabel.textColor = [UIColor colorWithRed:0.45
                                          green:1.0
                                           blue:0.65
                                          alpha:1.0];

    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Package Manager";
    subtitleLabel.font = [UIFont systemFontOfSize:17
                                            weight:UIFontWeightMedium];
    subtitleLabel.textColor = UIColor.whiteColor;

    UILabel *descriptionLabel = [[UILabel alloc] init];
    descriptionLabel.text =
        @"Browse repositories, inspect packages, and manage software "
         "for the hurr1c4ne environment.";
    descriptionLabel.font = [UIFont systemFontOfSize:14];
    descriptionLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    descriptionLabel.numberOfLines = 0;

    [self.contentStack addArrangedSubview:logoLabel];
    [self.contentStack addArrangedSubview:subtitleLabel];
    [self.contentStack addArrangedSubview:descriptionLabel];

    UIView *statusCard = [self makeCard];

    UIStackView *statusStack = [[UIStackView alloc] init];
    statusStack.axis = UILayoutConstraintAxisVertical;
    statusStack.spacing = 10;
    statusStack.translatesAutoresizingMaskIntoConstraints = NO;

    [statusCard addSubview:statusStack];

    [NSLayoutConstraint activateConstraints:@[
        [statusStack.topAnchor
         constraintEqualToAnchor:statusCard.topAnchor constant:18],
        [statusStack.leadingAnchor
         constraintEqualToAnchor:statusCard.leadingAnchor constant:18],
        [statusStack.trailingAnchor
         constraintEqualToAnchor:statusCard.trailingAnchor constant:-18],
        [statusStack.bottomAnchor
         constraintEqualToAnchor:statusCard.bottomAnchor constant:-18]
    ]];

    UILabel *statusHeading = [self makeLabel:@"Environment Status"
                                         size:18
                                        color:UIColor.whiteColor
                                        weight:UIFontWeightSemibold];

    self.statusLabel = [self makeLabel:@"Not connected to a package backend"
                                  size:14
                                 color:[UIColor colorWithWhite:0.75 alpha:1.0]
                                 weight:UIFontWeightRegular];
    self.statusLabel.numberOfLines = 0;

    [statusStack addArrangedSubview:statusHeading];
    [statusStack addArrangedSubview:self.statusLabel];

    [self.contentStack addArrangedSubview:statusCard];

    UIView *packagesCard = [self makeCard];

    UIStackView *packagesStack = [[UIStackView alloc] init];
    packagesStack.axis = UILayoutConstraintAxisVertical;
    packagesStack.spacing = 10;
    packagesStack.translatesAutoresizingMaskIntoConstraints = NO;

    [packagesCard addSubview:packagesStack];

    [NSLayoutConstraint activateConstraints:@[
        [packagesStack.topAnchor
         constraintEqualToAnchor:packagesCard.topAnchor constant:18],
        [packagesStack.leadingAnchor
         constraintEqualToAnchor:packagesCard.leadingAnchor constant:18],
        [packagesStack.trailingAnchor
         constraintEqualToAnchor:packagesCard.trailingAnchor constant:-18],
        [packagesStack.bottomAnchor
         constraintEqualToAnchor:packagesCard.bottomAnchor constant:-18]
    ]];

    UILabel *packagesHeading = [self makeLabel:@"Packages"
                                          size:18
                                         color:UIColor.whiteColor
                                         weight:UIFontWeightSemibold];

    self.packageCountLabel = [self makeLabel:@"No package index loaded"
                                         size:14
                                        color:[UIColor colorWithWhite:0.75 alpha:1.0]
                                        weight:UIFontWeightRegular];

    [packagesStack addArrangedSubview:packagesHeading];
    [packagesStack addArrangedSubview:self.packageCountLabel];

    [self.contentStack addArrangedSubview:packagesCard];

    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.refreshButton.backgroundColor =
        [UIColor colorWithRed:0.22 green:0.75 blue:0.46 alpha:1.0];
    self.refreshButton.layer.cornerRadius = 14;
    self.refreshButton.titleLabel.font =
        [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];

    [self.refreshButton setTitle:@"Check Environment"
                        forState:UIControlStateNormal];

    [self.refreshButton setTitleColor:UIColor.blackColor
                             forState:UIControlStateNormal];

    [self.refreshButton addTarget:self
                           action:@selector(checkEnvironment)
                 forControlEvents:UIControlEventTouchUpInside];

    [self.refreshButton.heightAnchor constraintEqualToConstant:52].active = YES;

    [self.contentStack addArrangedSubview:self.refreshButton];

    UILabel *footer = [[UILabel alloc] init];
    footer.text =
        @"Radix • Powered by the hurr1c4ne project\n"
         "Package installation requires a compatible backend.";
    footer.textColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    footer.font = [UIFont systemFontOfSize:12];
    footer.textAlignment = NSTextAlignmentCenter;
    footer.numberOfLines = 0;

    [self.contentStack addArrangedSubview:footer];
}

- (UIView *)makeCard {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0.10
                                           green:0.12
                                            blue:0.18
                                           alpha:1.0];
    card.layer.cornerRadius = 18;
    card.layer.borderWidth = 1;
    card.layer.borderColor =
        [UIColor colorWithWhite:1.0 alpha:0.08].CGColor;

    return card;
}

- (UILabel *)makeLabel:(NSString *)text
                  size:(CGFloat)size
                 color:(UIColor *)color
                weight:(UIFontWeight)weight {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = color;
    label.numberOfLines = 0;

    return label;
}

- (void)checkEnvironment {
    self.statusLabel.text =
        @"Radix is running. No privileged package backend is connected yet.";

    self.packageCountLabel.text =
        @"Repository refresh is not configured yet.";

    [self.refreshButton setTitle:@"Environment Checked"
                        forState:UIControlStateNormal];
}

@end
