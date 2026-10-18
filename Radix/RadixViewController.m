// Radix/RadixViewController.m

#import "RadixViewController.h"
#import <UIKit/UIKit.h>

#pragma mark - Package Model

@interface RXPackage : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *packageDescription;
@property (nonatomic, copy) NSString *architecture;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *dependencies;
@property (nonatomic, copy) NSString *repositoryURL;
@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, assign) unsigned long long size;

@end

@implementation RXPackage
@end

#pragma mark - Repository Model

@interface RXRepository : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) NSInteger packageCount;
@property (nonatomic, copy) NSString *status;

@end

@implementation RXRepository
@end

#pragma mark - Radix Interface

@interface RadixViewController () <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UILabel *headerTitle;
@property (nonatomic, strong) UILabel *headerSubtitle;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *tabBar;

@property (nonatomic, strong) NSMutableArray<UIButton *> *tabButtons;
@property (nonatomic, strong) NSMutableArray<RXPackage *> *packages;
@property (nonatomic, strong) NSMutableArray<RXRepository *> *repositories;
@property (nonatomic, strong) NSMutableArray<RXPackage *> *queue;
@property (nonatomic, strong) NSMutableArray<RXPackage *> *downloadedPackages;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UILabel *emptyTitle;
@property (nonatomic, strong) UILabel *emptyMessage;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, copy) NSArray<RXPackage *> *displayedPackages;
@property (nonatomic, copy) NSString *currentTab;
@property (nonatomic, copy) NSString *searchQuery;

@property (nonatomic, assign) BOOL refreshing;

@end

@implementation RadixViewController

#pragma mark - Colors

- (UIColor *)backgroundColor {
    return [UIColor colorWithRed:0.035 green:0.047 blue:0.075 alpha:1.0];
}

- (UIColor *)surfaceColor {
    return [UIColor colorWithRed:0.075 green:0.09 blue:0.13 alpha:1.0];
}

- (UIColor *)secondarySurfaceColor {
    return [UIColor colorWithRed:0.105 green:0.125 blue:0.17 alpha:1.0];
}

- (UIColor *)accentColor {
    return [UIColor colorWithRed:0.35 green:0.95 blue:0.61 alpha:1.0];
}

- (UIColor *)mutedColor {
    return [UIColor colorWithWhite:0.61 alpha:1.0];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = self.backgroundColor;
    self.navigationController.navigationBarHidden = YES;

    self.packages = [NSMutableArray array];
    self.repositories = [NSMutableArray array];
    self.queue = [NSMutableArray array];
    self.downloadedPackages = [NSMutableArray array];
    self.tabButtons = [NSMutableArray array];

    self.displayedPackages = @[];
    self.currentTab = @"Home";
    self.searchQuery = @"";

    [self loadRepositories];
    [self loadDownloadedPackages];
    [self buildInterface];
    [self showTab:@"Home"];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.headerView.layer.cornerRadius = 0;
}

#pragma mark - Interface

- (void)buildInterface {
    self.headerView = [[UIView alloc] init];
    self.headerView.backgroundColor = self.backgroundColor;
    self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerView];

    UILabel *brand = [[UILabel alloc] init];
    brand.text = @"radix";
    brand.font = [UIFont systemFontOfSize:31 weight:UIFontWeightBlack];
    brand.textColor = self.accentColor;
    brand.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"PACKAGE MANAGER";
    subtitle.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
    subtitle.textColor = self.mutedColor;
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.letterSpacing = 1.5;

    UIView *statusDot = [[UIView alloc] init];
    statusDot.backgroundColor = self.accentColor;
    statusDot.layer.cornerRadius = 4;
    statusDot.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *statusText = [[UILabel alloc] init];
    statusText.text = @"READY";
    statusText.font = [UIFont monospacedSystemFontOfSize:10 weight:UIFontWeightBold];
    statusText.textColor = self.accentColor;
    statusText.translatesAutoresizingMaskIntoConstraints = NO;

    [self.headerView addSubview:brand];
    [self.headerView addSubview:subtitle];
    [self.headerView addSubview:statusDot];
    [self.headerView addSubview:statusText];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.contentView];

    self.tabBar = [[UIView alloc] init];
    self.tabBar.backgroundColor = self.surfaceColor;
    self.tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tabBar];

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tabBar addSubview:separator];

    NSArray<NSString *> *titles = @[
        @"Home", @"Packages", @"Sources", @"Queue", @"Installed"
    ];

    NSArray<NSString *> *symbols = @[
        @"square.grid.2x2.fill",
        @"shippingbox.fill",
        @"externaldrive.fill",
        @"arrow.down.circle.fill",
        @"checkmark.circle.fill"
    ];

    CGFloat tabWidth = UIScreen.mainScreen.bounds.size.width / titles.count;

    for (NSUInteger i = 0; i < titles.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.translatesAutoresizingMaskIntoConstraints = NO;

        UIStackView *stack = [[UIStackView alloc] init];
        stack.axis = UILayoutConstraintAxisVertical;
        stack.alignment = UIStackViewAlignmentCenter;
        stack.spacing = 5;
        stack.userInteractionEnabled = NO;
        stack.translatesAutoresizingMaskIntoConstraints = NO;

        UIImageView *icon = [[UIImageView alloc]
            initWithImage:[UIImage systemImageNamed:symbols[i]]];

        icon.contentMode = UIViewContentModeScaleAspectFit;
        icon.tintColor = self.mutedColor;
        icon.tag = 100;

        UILabel *label = [[UILabel alloc] init];
        label.text = titles[i];
        label.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
        label.textColor = self.mutedColor;
        label.tag = 101;

        [stack addArrangedSubview:icon];
        [stack addArrangedSubview:label];

        [button addSubview:stack];

        [NSLayoutConstraint activateConstraints:@[
            [stack.centerXAnchor constraintEqualToAnchor:button.centerXAnchor],
            [stack.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
            [icon.widthAnchor constraintEqualToConstant:21],
            [icon.heightAnchor constraintEqualToConstant:21]
        ]];

        [button addTarget:self
                   action:@selector(tabTapped:)
         forControlEvents:UIControlEventTouchUpInside];

        [self.tabBar addSubview:button];
        [self.tabButtons addObject:button];

        [NSLayoutConstraint activateConstraints:@[
            [button.topAnchor constraintEqualToAnchor:self.tabBar.topAnchor constant:1],
            [button.bottomAnchor constraintEqualToAnchor:self.tabBar.safeAreaLayoutGuide.bottomAnchor],
            [button.widthAnchor constraintEqualToConstant:tabWidth],
            [button.leadingAnchor constraintEqualToAnchor:self.tabBar.leadingAnchor
                                                constant:tabWidth * i]
        ]];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.headerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerView.heightAnchor constraintEqualToConstant:75],

        [brand.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor constant:22],
        [brand.topAnchor constraintEqualToAnchor:self.headerView.topAnchor constant:3],

        [subtitle.leadingAnchor constraintEqualToAnchor:brand.leadingAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:-2],

        [statusText.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor constant:-22],
        [statusText.centerYAnchor constraintEqualToAnchor:brand.centerYAnchor],

        [statusDot.trailingAnchor constraintEqualToAnchor:statusText.leadingAnchor constant:-7],
        [statusDot.centerYAnchor constraintEqualToAnchor:statusText.centerYAnchor],
        [statusDot.widthAnchor constraintEqualToConstant:8],
        [statusDot.heightAnchor constraintEqualToConstant:8],

        [self.contentView.topAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.tabBar.topAnchor],

        [self.tabBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tabBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tabBar.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.tabBar.heightAnchor constraintEqualToConstant:85],

        [separator.topAnchor constraintEqualToAnchor:self.tabBar.topAnchor],
        [separator.leadingAnchor constraintEqualToAnchor:self.tabBar.leadingAnchor],
        [separator.trailingAnchor constraintEqualToAnchor:self.tabBar.trailingAnchor],
        [separator.heightAnchor constraintEqualToConstant:1]
    ]];
}

#pragma mark - Navigation

- (void)tabTapped:(UIButton *)sender {
    NSArray *tabs = @[@"Home", @"Packages", @"Sources", @"Queue", @"Installed"];

    if (sender.tag < tabs.count) {
        [self showTab:tabs[sender.tag]];
    }
}

- (void)showTab:(NSString *)tab {
    self.currentTab = tab;

    for (NSUInteger i = 0; i < self.tabButtons.count; i++) {
        UIButton *button = self.tabButtons[i];

        UIImageView *icon = nil;
        UILabel *label = nil;

        for (UIView *subview in button.subviews) {
            if (![subview isKindOfClass:[UIStackView class]]) continue;

            for (UIView *item in ((UIStackView *)subview).arrangedSubviews) {
                if (item.tag == 100) icon = (UIImageView *)item;
                if (item.tag == 101) label = (UILabel *)item;
            }
        }

        NSString *buttonTitle = @[@"Home", @"Packages", @"Sources",
                                  @"Queue", @"Installed"][i];

        BOOL selected = [buttonTitle isEqualToString:tab];

        icon.tintColor = selected ? self.accentColor : self.mutedColor;
        label.textColor = selected ? self.accentColor : self.mutedColor;
    }

    for (UIView *view in self.contentView.subviews) {
        [view removeFromSuperview];
    }

    self.tableView = nil;
    self.searchBar = nil;
    self.emptyTitle = nil;
    self.emptyMessage = nil;

    if ([tab isEqualToString:@"Home"]) {
        [self showHome];
    } else if ([tab isEqualToString:@"Packages"]) {
        [self showPackages];
    } else if ([tab isEqualToString:@"Sources"]) {
        [self showSources];
    } else if ([tab isEqualToString:@"Queue"]) {
        [self showQueue];
    } else if ([tab isEqualToString:@"Installed"]) {
        [self showInstalled];
    }
}

#pragma mark - UI Helpers

- (UILabel *)label:(NSString *)text
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

- (UIView *)card {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = self.surfaceColor;
    view.layer.cornerRadius = 17;
    view.layer.borderWidth = 1;
    view.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.055].CGColor;
    return view;
}

- (UIButton *)button:(NSString *)title
           background:(UIColor *)background
                 icon:(NSString *)symbol {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.backgroundColor = background;
    button.layer.cornerRadius = 12;
    button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];

    UIImage *image = [UIImage systemImageNamed:symbol];

    [button setImage:image forState:UIControlStateNormal];
    [button setTitle:[@"  " stringByAppendingString:title]
            forState:UIControlStateNormal];

    button.tintColor = UIColor.blackColor;
    [button setTitleColor:UIColor.blackColor forState:UIControlStateNormal];

    button.contentEdgeInsets = UIEdgeInsetsMake(12, 14, 12, 14);
    return button;
}

- (void)addSubview:(UIView *)view
           toStack:(UIStackView *)stack
          spacing:(CGFloat)spacing {
    [stack addArrangedSubview:view];
    [view.heightAnchor constraintGreaterThanOrEqualToConstant:1].active = YES;
    stack.spacing = spacing;
}

- (UIStackView *)verticalStack {
    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentFill;
    stack.spacing = 15;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    return stack;
}

- (void)installStack:(UIStackView *)stack {
    [self.contentView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:20],
        [stack.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.contentView.bottomAnchor constant:-20]
    ]];
}

#pragma mark - Home

- (void)showHome {
    UIStackView *stack = [self verticalStack];
    [self installStack:stack];

    UILabel *greeting = [self label:@"Your packages.\nYour environment."
                               size:28
                              color:UIColor.whiteColor
                             weight:UIFontWeightBold];

    UILabel *intro = [self label:@"Explore software from your configured repositories."
                            size:14
                           color:self.mutedColor
                          weight:UIFontWeightRegular];

    [stack addArrangedSubview:greeting];
    [stack addArrangedSubview:intro];

    UIView *overview = [self card];
    overview.translatesAutoresizingMaskIntoConstraints = NO;
    [overview.heightAnchor constraintEqualToConstant:125].active = YES;

    UIStackView *overviewStack = [self verticalStack];
    overviewStack.spacing = 9;
    [overview addSubview:overviewStack];

    [NSLayoutConstraint activateConstraints:@[
        [overviewStack.topAnchor constraintEqualToAnchor:overview.topAnchor constant:17],
        [overviewStack.leadingAnchor constraintEqualToAnchor:overview.leadingAnchor constant:17],
        [overviewStack.trailingAnchor constraintEqualToAnchor:overview.trailingAnchor constant:-17],
        [overviewStack.bottomAnchor constraintEqualToAnchor:overview.bottomAnchor constant:-17]
    ]];

    UILabel *repoTitle = [self label:@"REPOSITORIES"
                                size:11
                               color:self.mutedColor
                              weight:UIFontWeightBold];

    UILabel *repoCount = [self label:
        [NSString stringWithFormat:@"%lu configured",
         (unsigned long)self.repositories.count]
                                size:21
                               color:UIColor.whiteColor
                              weight:UIFontWeightBold];

    UILabel *packageCount = [self label:
        [NSString stringWithFormat:@"%lu packages indexed",
         (unsigned long)self.packages.count]
                                  size:13
                                 color:self.accentColor
                                weight:UIFontWeightMedium];

    [overviewStack addArrangedSubview:repoTitle];
    [overviewStack addArrangedSubview:repoCount];
    [overviewStack addArrangedSubview:packageCount];

    [stack addArrangedSubview:overview];

    UILabel *section = [self label:@"Quick actions"
                               size:19
                              color:UIColor.whiteColor
                             weight:UIFontWeightBold];

    [stack addArrangedSubview:section];

    NSArray *actions = @[
        @[@"Browse Packages", @"shippingbox.fill", @"Packages"],
        @[@"Manage Sources", @"externaldrive.fill", @"Sources"],
        @[@"View Queue", @"arrow.down.circle.fill", @"Queue"]
    ];

    for (NSArray *action in actions) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.backgroundColor = self.surfaceColor;
        button.layer.cornerRadius = 14;
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        button.contentEdgeInsets = UIEdgeInsetsMake(17, 17, 17, 17);
        button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];

        [button setImage:[UIImage systemImageNamed:action[1]]
                forState:UIControlStateNormal];
        [button setTitle:[@"   " stringByAppendingString:action[0]]
                forState:UIControlStateNormal];

        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.tintColor = self.accentColor;
        button.heightAnchor.constraintEqualToConstant:57].active = YES;

        NSString *destination = action[2];
        [button addAction:[UIAction actionWithHandler:^(__kindof UIAction *a) {
            [self showTab:destination];
        }] forControlEvents:UIControlEventTouchUpInside];

        [stack addArrangedSubview:button];
    }

    UIView *notice = [self card];
    notice.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *noticeStack = [self verticalStack];
    noticeStack.spacing = 7;
    [notice addSubview:noticeStack];

    [NSLayoutConstraint activateConstraints:@[
        [noticeStack.topAnchor constraintEqualToAnchor:notice.topAnchor constant:16],
        [noticeStack.leadingAnchor constraintEqualToAnchor:notice.leadingAnchor constant:16],
        [noticeStack.trailingAnchor constraintEqualToAnchor:notice.trailingAnchor constant:-16],
        [noticeStack.bottomAnchor constraintEqualToAnchor:notice.bottomAnchor constant:-16]
    ]];

    [noticeStack addArrangedSubview:
        [self label:@"INSTALLATION BACKEND"
                size:11
               color:self.accentColor
              weight:UIFontWeightBold]];

    [noticeStack addArrangedSubview:
        [self label:@"Repository browsing and package downloads are separate from installing software into /var/jb. A compatible privileged backend is required for actual installation."
                size:13
               color:self.mutedColor
              weight:UIFontWeightRegular]];

    [stack addArrangedSubview:notice];
}

#pragma mark - Packages

- (void)showPackages {
    UIStackView *stack = [self verticalStack];
    stack.spacing = 12;
    [self installStack:stack];

    UILabel *title = [self label:@"Packages"
                            size:27
                           color:UIColor.whiteColor
                          weight:UIFontWeightBold];

    [stack addArrangedSubview:title];

    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search packages";
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = UIColor.clearColor;
    self.searchBar.barTintColor = self.backgroundColor;
    self.searchBar.tintColor = self.accentColor;

    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    searchField.textColor = UIColor.whiteColor;
    searchField.backgroundColor = self.surfaceColor;

    [stack addArrangedSubview:self.searchBar];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStylePlain];

    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = 88;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;

    [self.tableView registerClass:UITableViewCell.class
           forCellReuseIdentifier:@"PackageCell"];

    [stack addArrangedSubview:self.tableView];

    [self.tableView.heightAnchor constraintEqualToConstant:430].active = YES;

    [self applyPackageFilter];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchQuery = searchText ?: @"";
    [self applyPackageFilter];
}

- (void)applyPackageFilter {
    NSString *query = self.searchQuery.lowercaseString;

    if (query.length == 0) {
        self.displayedPackages = [self.packages copy];
    } else {
        NSPredicate *predicate =
        [NSPredicate predicateWithBlock:^BOOL(RXPackage *package, NSDictionary *bindings) {
            return [package.name.lowercaseString containsString:query] ||
                   [package.packageDescription.lowercaseString containsString:query];
        }];

        self.displayedPackages = [self.packages filteredArrayUsingPredicate:predicate];
    }

    [self.tableView reloadData];
}

#pragma mark - Sources

- (void)showSources {
    UIStackView *stack = [self verticalStack];
    [self installStack:stack];

    UILabel *title = [self label:@"Sources"
                            size:27
                           color:UIColor.whiteColor
                          weight:UIFontWeightBold];

    UILabel *description = [self label:
        @"Manage repository index URLs. This version accepts direct Debian Packages index URLs."
                                             size:13
                                            color:self.mutedColor
                                           weight:UIFontWeightRegular];

    [stack addArrangedSubview:title];
    [stack addArrangedSubview:description];

    UIButton *addButton = [self button:@"Add Source"
                            background:self.accentColor
                                  icon:@"plus"];

    [addButton addTarget:self
                  action:@selector(addSource)
        forControlEvents:UIControlEventTouchUpInside];

    [stack addArrangedSubview:addButton];

    if (self.repositories.count == 0) {
        [stack addArrangedSubview:
            [self label:@"No sources configured"
                    size:17
                   color:UIColor.whiteColor
                  weight:UIFontWeightSemibold]];

        [stack addArrangedSubview:
            [self label:@"Add a repository index URL to begin browsing packages."
                    size:13
                   color:self.mutedColor
                  weight:UIFontWeightRegular]];
    }

    for (NSUInteger i = 0; i < self.repositories.count; i++) {
        RXRepository *repository = self.repositories[i];

        UIView *card = [self card];
        UIStackView *cardStack = [self verticalStack];
        cardStack.spacing = 8;

        [card addSubview:cardStack];

        [NSLayoutConstraint activateConstraints:@[
            [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
            [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],
            [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],
            [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-15]
        ]];

        [cardStack addArrangedSubview:
            [self label:repository.name
                    size:16
                   color:UIColor.whiteColor
                  weight:UIFontWeightSemibold]];

        [cardStack addArrangedSubview:
            [self label:repository.url
                    size:11
                   color:self.mutedColor
                  weight:UIFontWeightRegular]];

        [cardStack addArrangedSubview:
            [self label:[NSString stringWithFormat:@"%@ • %ld packages",
                         repository.status,
                         (long)repository.packageCount]
                    size:12
                   color:self.accentColor
                  weight:UIFontWeightMedium]];

        UIStackView *actions = [[UIStackView alloc] init];
        actions.axis = UILayoutConstraintAxisHorizontal;
        actions.spacing = 10;
        actions.distribution = UIStackViewDistributionFillEqually;

        UIButton *refresh = [UIButton buttonWithType:UIButtonTypeSystem];
        [refresh setTitle:@"Refresh" forState:UIControlStateNormal];
        refresh.tintColor = self.accentColor;
        refresh.tag = i;
        [refresh addTarget:self
                    action:@selector(refreshSource:)
          forControlEvents:UIControlEventTouchUpInside];

        UIButton *remove = [UIButton buttonWithType:UIButtonTypeSystem];
        [remove setTitle:@"Remove" forState:UIControlStateNormal];
        [remove setTitleColor:[UIColor systemRedColor] forState:UIControlStateNormal];
        remove.tag = i;
        [remove addTarget:self
                   action:@selector(removeSource:)
         forControlEvents:UIControlEventTouchUpInside];

        [actions addArrangedSubview:refresh];
        [actions addArrangedSubview:remove];
        [cardStack addArrangedSubview:actions];

        [stack addArrangedSubview:card];
    }
}

- (void)addSource {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"Add Repository"
                                            message:@"Enter a name and a direct Debian Packages index URL."
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Repository name";
        field.autocapitalizationType = UITextAutocapitalizationTypeWords;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"https://example.org/Packages";
        field.keyboardType = UIKeyboardTypeURL;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Add"
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
        NSString *name = alert.textFields[0].text ?: @"";
        NSString *urlString = alert.textFields[1].text ?: @"";

        NSURLComponents *components =
            [NSURLComponents componentsWithString:urlString];

        BOOL valid =
            name.length > 0 &&
            components.host.length > 0 &&
            ([components.scheme.lowercaseString isEqualToString:@"https"] ||
             [components.scheme.lowercaseString isEqualToString:@"http"]);

        if (!valid) {
            [self showMessage:@"Invalid source"
                      message:@"Enter a source name and a valid HTTP or HTTPS URL."];
            return;
        }

        for (RXRepository *existing in self.repositories) {
            if ([existing.url isEqualToString:urlString]) {
                [self showMessage:@"Source already exists"
                          message:@"This repository URL has already been added."];
                return;
            }
        }

        RXRepository *repository = [[RXRepository alloc] init];
        repository.name = name;
        repository.url = urlString;
        repository.enabled = YES;
        repository.packageCount = 0;
        repository.status = @"Not refreshed";

        [self.repositories addObject:repository];
        [self saveRepositories];
        [self showTab:@"Sources"];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)removeSource:(UIButton *)sender {
    if (sender.tag >= self.repositories.count) return;

    [self.repositories removeObjectAtIndex:sender.tag];
    [self saveRepositories];
    [self showTab:@"Sources"];
}

- (void)refreshSource:(UIButton *)sender {
    if (sender.tag >= self.repositories.count) return;

    RXRepository *repository = self.repositories[sender.tag];

    NSURL *url = [NSURL URLWithString:repository.url];

    if (!url) {
        [self showMessage:@"Invalid URL" message:@"The repository URL could not be opened."];
        return;
    }

    repository.status = @"Refreshing…";
    [self showTab:@"Sources"];

    NSURLSessionDataTask *task =
    [[NSURLSession sharedSession]
     dataTaskWithURL:url
     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if (error || !data) {
                repository.status = @"Refresh failed";
                [self saveRepositories];
                [self showTab:@"Sources"];

                [self showMessage:@"Repository refresh failed"
                          message:error.localizedDescription ?: @"No data received."];
                return;
            }

            NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;

            if (![http isKindOfClass:NSHTTPURLResponse.class] ||
                http.statusCode < 200 || http.statusCode >= 300) {

                repository.status = @"HTTP error";
                [self saveRepositories];
                [self showTab:@"Sources"];
                return;
            }

            NSString *contents = [[NSString alloc] initWithData:data
                                                       encoding:NSUTF8StringEncoding];

            if (!contents) {
                repository.status = @"Invalid index";
                [self saveRepositories];
                [self showTab:@"Sources"];
                return;
            }

            NSArray<RXPackage *> *parsed =
                [self parseIndex:contents repository:repository];

            NSMutableDictionary<NSString *, RXPackage *> *merged =
                [NSMutableDictionary dictionary];

            for (RXPackage *package in self.packages) {
                merged[package.name] = package;
            }

            for (RXPackage *package in parsed) {
                merged[package.name] = package;
            }

            self.packages = [NSMutableArray arrayWithArray:merged.allValues];

            repository.packageCount = parsed.count;
            repository.status = @"Refreshed";

            [self saveRepositories];
            [self savePackageIndex];

            if ([self.currentTab isEqualToString:@"Sources"]) {
                [self showTab:@"Sources"];
            } else if ([self.currentTab isEqualToString:@"Packages"]) {
                [self applyPackageFilter];
            }
        });
    }];

    [task resume];
}

#pragma mark - Debian Index Parser

- (NSArray<RXPackage *> *)parseIndex:(NSString *)contents
                          repository:(RXRepository *)repository {

    NSMutableArray<RXPackage *> *result = [NSMutableArray array];

    NSArray<NSString *> *stanzas =
        [contents componentsSeparatedByString:@"\n\n"];

    for (NSString *stanza in stanzas) {
        NSMutableDictionary<NSString *, NSString *> *fields =
            [NSMutableDictionary dictionary];

        NSString *currentKey = nil;

        for (NSString *line in [stanza componentsSeparatedByCharactersInSet:
                                NSCharacterSet.newlineCharacterSet]) {

            if (line.length == 0) continue;

            unichar first = [line characterAtIndex:0];

            if ((first == ' ' || first == '\t') && currentKey.length > 0) {
                fields[currentKey] = [NSString stringWithFormat:@"%@\n%@",
                                      fields[currentKey] ?: @"", line];
                continue;
            }

            NSRange colon = [line rangeOfString:@":"];

            if (colon.location == NSNotFound || colon.location == 0) {
                currentKey = nil;
                continue;
            }

            currentKey = [[line substringToIndex:colon.location] lowercaseString];

            fields[currentKey] =
                [[line substringFromIndex:colon.location + 1]
                 stringByTrimmingCharactersInSet:
                 NSCharacterSet.whitespaceCharacterSet];
        }

        if (fields[@"package"].length == 0 ||
            fields[@"version"].length == 0) {
            continue;
        }

        RXPackage *package = [[RXPackage alloc] init];

        package.name = fields[@"package"];
        package.version = fields[@"version"];
        package.packageDescription =
            fields[@"description"] ?: @"No description provided.";

        package.architecture = fields[@"architecture"] ?: @"unknown";
        package.filename = fields[@"filename"] ?: @"";
        package.dependencies = fields[@"depends"] ?: @"";
        package.repositoryURL = repository.url;
        package.size = [fields[@"size"] longLongValue];

        if (package.filename.length > 0) {
            NSURL *base = [NSURL URLWithString:repository.url];
            NSURL *download =
                [NSURL URLWithString:package.filename relativeToURL:base];

            package.downloadURL = download.absoluteURL.absoluteString ?: @"";
        } else {
            package.downloadURL = @"";
        }

        [result addObject:package];
    }

    return result;
}

#pragma mark - Queue

- (void)showQueue {
    UIStackView *stack = [self verticalStack];
    [self installStack:stack];

    UILabel *title = [self label:@"Queue"
                            size:27
                           color:UIColor.whiteColor
                          weight:UIFontWeightBold];

    UILabel *description = [self label:
        @"Review package downloads requested during this session."
                                             size:13
                                            color:self.mutedColor
                                           weight:UIFontWeightRegular];

    [stack addArrangedSubview:title];
    [stack addArrangedSubview:description];

    if (self.queue.count == 0) {
        [stack addArrangedSubview:
            [self label:@"Your queue is empty"
                    size:19
                   color:UIColor.whiteColor
                  weight:UIFontWeightSemibold]];

        [stack addArrangedSubview:
            [self label:@"Browse packages and open a package to add it to your download queue."
                    size:13
                   color:self.mutedColor
                  weight:UIFontWeightRegular]];
        return;
    }

    UIButton *downloadAll = [self button:@"Download All"
                              background:self.accentColor
                                    icon:@"arrow.down.to.line"];

    [downloadAll addTarget:self
                    action:@selector(downloadAllQueued)
          forControlEvents:UIControlEventTouchUpInside];

    [stack addArrangedSubview:downloadAll];

    for (RXPackage *package in self.queue) {
        UIView *card = [self card];
        UIStackView *cardStack = [self verticalStack];
        cardStack.spacing = 7;

        [card addSubview:cardStack];

        [NSLayoutConstraint activateConstraints:@[
            [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
            [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],
            [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],
            [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-15]
        ]];

        [cardStack addArrangedSubview:
            [self label:package.name
                    size:15
                   color:UIColor.whiteColor
                  weight:UIFontWeightSemibold]];

        [cardStack addArrangedSubview:
            [self label:[NSString stringWithFormat:@"Version %@", package.version]
                    size:12
                   color:self.mutedColor
                  weight:UIFontWeightRegular]];

        [stack addArrangedSubview:card];
    }
}

- (void)downloadAllQueued {
    NSArray<RXPackage *> *items = [self.queue copy];

    if (items.count == 0) return;

    [self downloadNextPackageAtIndex:0 packages:items];
}

- (void)downloadNextPackageAtIndex:(NSUInteger)index
                          packages:(NSArray<RXPackage *> *)items {
    if (index >= items.count) {
        [self showTab:@"Queue"];
        [self showMessage:@"Downloads finished"
                  message:@"All download attempts have completed. Check the results for any failures."];
        return;
    }

    RXPackage *package = items[index];

    [self downloadPackage:package completion:^(BOOL success, NSString *message) {
        if (!success) {
            [self showMessage:@"Download failed"
                      message:[NSString stringWithFormat:@"%@: %@", package.name, message]];
        }

        [self downloadNextPackageAtIndex:index + 1 packages:items];
    }];
}

- (void)enqueuePackage:(RXPackage *)package {
    for (RXPackage *existing in self.queue) {
        if ([existing.name isEqualToString:package.name]) {
            [self showMessage:@"Already queued"
                      message:[NSString stringWithFormat:@"%@ is already in the queue.", package.name]];
            return;
        }
    }

    [self.queue addObject:package];
    [self showMessage:@"Added to queue"
              message:[NSString stringWithFormat:@"%@ %@ is queued for download.", package.name, package.version]];
}

#pragma mark - Installed / Downloaded

- (void)showInstalled {
    UIStackView *stack = [self verticalStack];
    [self installStack:stack];

    [stack addArrangedSubview:
        [self label:@"Installed"
                size:27
               color:UIColor.whiteColor
              weight:UIFontWeightBold]];

    [stack addArrangedSubview:
        [self label:@"Packages successfully downloaded by Radix."
                size:13
               color:self.mutedColor
              weight:UIFontWeightRegular]];

    if (self.downloadedPackages.count == 0) {
        [stack addArrangedSubview:
            [self label:@"No downloaded packages yet"
                    size:17
                   color:UIColor.whiteColor
                  weight:UIFontWeightSemibold]];

        [stack addArrangedSubview:
            [self label:@"Downloaded .deb files will appear here. A downloaded file is not the same as a package installed into the jailbreak environment."
                    size:13
                   color:self.mutedColor
                  weight:UIFontWeightRegular]];
        return;
    }

    for (RXPackage *package in self.downloadedPackages) {
        UIView *card = [self card];
        UIStackView *cardStack = [self verticalStack];
        cardStack.spacing = 7;

        [card addSubview:cardStack];

        [NSLayoutConstraint activateConstraints:@[
            [cardStack.topAnchor constraintEqualToAnchor:card.topAnchor constant:15],
            [cardStack.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:15],
            [cardStack.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-15],
            [cardStack.bottomAnchor constraintEqualToAnchor:card.bottomAnchor constant:-15]
        ]];

        [cardStack addArrangedSubview:
            [self label:package.name
                    size:15
                   color:UIColor.whiteColor
                  weight:UIFontWeightSemibold]];

        [cardStack addArrangedSubview:
            [self label:[NSString stringWithFormat:@"Downloaded • %@", package.version]
                    size:12
                   color:self.accentColor
                  weight:UIFontWeightMedium]];

        [stack addArrangedSubview:card];
    }
}

#pragma mark - Package Details

- (void)showPackageDetails:(RXPackage *)package {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:package.name
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleAlert];

    NSMutableString *details = [NSMutableString string];

    [details appendFormat:@"Version: %@\n", package.version];
    [details appendFormat:@"Architecture: %@\n\n", package.architecture];
    [details appendFormat:@"%@\n\n", package.packageDescription];

    if (package.dependencies.length > 0) {
        [details appendFormat:@"Dependencies:\n%@\n\n", package.dependencies];
    }

    [details appendFormat:@"Download size: %llu bytes\n", package.size];
    [details appendFormat:@"Repository:\n%@", package.repositoryURL];

    alert.message = details;

    [alert addAction:[UIAlertAction actionWithTitle:@"Close"
                                             style:UIAlertActionStyleCancel
                                           handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Add to Queue"
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
        [self enqueuePackage:package];
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Download .deb"
                                             style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
        [self downloadPackage:package completion:^(BOOL success, NSString *message) {
            [self showMessage:success ? @"Download complete" : @"Download failed"
                      message:message];
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Downloads

- (void)downloadPackage:(RXPackage *)package
             completion:(void (^)(BOOL success, NSString *message))completion {

    if (package.downloadURL.length == 0) {
        completion(NO, @"No Filename field was provided in the package index.");
        return;
    }

    NSURL *url = [NSURL URLWithString:package.downloadURL];

    if (!url ||
        !([url.scheme.lowercaseString isEqualToString:@"https"] ||
          [url.scheme.lowercaseString isEqualToString:@"http"])) {
        completion(NO, @"The package download URL is invalid.");
        return;
    }

    NSURLSessionDownloadTask *task =
    [[NSURLSession sharedSession]
     downloadTaskWithURL:url
     completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {

        if (error || !location) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, error.localizedDescription ?: @"Download failed.");
            });
            return;
        }

        NSHTTPURLResponse *http = (NSHTTPURLResponse *)response;

        if (![http isKindOfClass:NSHTTPURLResponse.class] ||
            http.statusCode < 200 || http.statusCode >= 300) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, @"The server returned an unsuccessful HTTP status.");
            });
            return;
        }

        NSURL *documents =
            [[[NSFileManager defaultManager]
              URLsForDirectory:NSDocumentDirectory
                     inDomains:NSUserDomainMask] firstObject];

        NSURL *directory =
            [documents URLByAppendingPathComponent:@"RadixDownloads"
                                       isDirectory:YES];

        NSError *directoryError = nil;

        [[NSFileManager defaultManager]
         createDirectoryAtURL:directory
         withIntermediateDirectories:YES
         attributes:nil
         error:&directoryError];

        if (directoryError) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, directoryError.localizedDescription);
            });
            return;
        }

        NSString *safeName =
            [package.name stringByReplacingOccurrencesOfString:@"/"
                                                    withString:@"_"];

        NSString *fileName =
            [NSString stringWithFormat:@"%@_%@.deb", safeName, package.version];

        NSURL *destination = [directory URLByAppendingPathComponent:fileName];

        NSError *moveError = nil;
        NSFileManager *fm = [NSFileManager defaultManager];

        if ([fm fileExistsAtPath:destination.path]) {
            [fm removeItemAtURL:destination error:nil];
        }

        [fm moveItemAtURL:location toURL:destination error:&moveError];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (moveError) {
                completion(NO, moveError.localizedDescription);
                return;
            }

            BOOL alreadyRecorded = NO;

            for (RXPackage *existing in self.downloadedPackages) {
                if ([existing.name isEqualToString:package.name] &&
                    [existing.version isEqualToString:package.version]) {
                    alreadyRecorded = YES;
                    break;
                }
            }

            if (!alreadyRecorded) {
                [self.downloadedPackages addObject:package];
            }

            [self.queue removeObject:package];

            [self saveDownloadedPackages];
            [self showTab:@"Queue"];

            completion(YES, [NSString stringWithFormat:
                @"%@ was downloaded to Radix's private Documents directory. It has not been installed into /var/jb.",
                package.name]);
        });
    }];

    [task resume];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return self.displayedPackages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"PackageCell"
                                        forIndexPath:indexPath];

    RXPackage *package = self.displayedPackages[indexPath.row];

    cell.backgroundColor = UIColor.clearColor;
    cell.contentView.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    cell.textLabel.text = package.name;
    cell.textLabel.textColor = UIColor.whiteColor;
    cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];

    cell.detailTextLabel.text = nil;

    UILabel *description = [cell.contentView viewWithTag:300];

    if (!description) {
        description = [[UILabel alloc] init];
        description.tag = 300;
        description.font = [UIFont systemFontOfSize:12];
        description.textColor = self.mutedColor;
        description.numberOfLines = 2;
        description.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:description];

        [NSLayoutConstraint activateConstraints:@[
            [description.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:15],
            [description.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-12],
            [description.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:43],
            [description.bottomAnchor constraintLessThanOrEqualToAnchor:cell.contentView.bottomAnchor constant:-6]
        ]];
    }

    description.text = [NSString stringWithFormat:@"%@  •  %@",
                        package.packageDescription,
                        package.version];

    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.displayedPackages.count) {
        [self showPackageDetails:self.displayedPackages[indexPath.row]];
    }
}

#pragma mark - Persistence

- (NSURL *)radixDirectory {
    NSURL *documents =
        [[[NSFileManager defaultManager]
          URLsForDirectory:NSDocumentDirectory
                 inDomains:NSUserDomainMask] firstObject];

    NSURL *directory =
        [documents URLByAppendingPathComponent:@"Radix"
                                   isDirectory:YES];

    [[NSFileManager defaultManager]
     createDirectoryAtURL:directory
     withIntermediateDirectories:YES
     attributes:nil
     error:nil];

    return directory;
}

- (void)loadRepositories {
    NSURL *file = [[self radixDirectory] URLByAppendingPathComponent:@"Sources.plist"];

    NSArray *saved = [NSArray arrayWithContentsOfURL:file];

    for (NSDictionary *entry in saved) {
        if (![entry isKindOfClass:NSDictionary.class]) continue;

        RXRepository *repository = [[RXRepository alloc] init];
        repository.name = entry[@"name"] ?: @"Repository";
        repository.url = entry[@"url"] ?: @"";
        repository.enabled = [entry[@"enabled"] boolValue];
        repository.packageCount = [entry[@"count"] integerValue];
        repository.status = entry[@"status"] ?: @"Not refreshed";

        if (repository.url.length > 0) {
            [self.repositories addObject:repository];
        }
    }

    NSURL *indexFile =
        [[self radixDirectory] URLByAppendingPathComponent:@"Packages.plist"];

    NSArray *savedPackages = [NSArray arrayWithContentsOfURL:indexFile];

    for (NSDictionary *entry in savedPackages) {
        RXPackage *package = [self packageFromDictionary:entry];

        if (package) {
            [self.packages addObject:package];
        }
    }
}

- (void)saveRepositories {
    NSMutableArray *saved = [NSMutableArray array];

    for (RXRepository *repository in self.repositories) {
        [saved addObject:@{
            @"name": repository.name ?: @"",
            @"url": repository.url ?: @"",
            @"enabled": @(repository.enabled),
            @"count": @(repository.packageCount),
            @"status": repository.status ?: @""
        }];
    }

    [saved writeToURL:
        [[self radixDirectory] URLByAppendingPathComponent:@"Sources.plist"]
           atomically:YES];
}

- (void)savePackageIndex {
    NSMutableArray *saved = [NSMutableArray array];

    for (RXPackage *package in self.packages) {
        [saved addObject:[self dictionaryFromPackage:package]];
    }

    [saved writeToURL:
        [[self radixDirectory] URLByAppendingPathComponent:@"Packages.plist"]
           atomically:YES];
}

- (void)loadDownloadedPackages {
    NSURL *file =
        [[self radixDirectory] URLByAppendingPathComponent:@"Downloaded.plist"];

    NSArray *saved = [NSArray arrayWithContentsOfURL:file];

    for (NSDictionary *entry in saved) {
        RXPackage *package = [self packageFromDictionary:entry];

        if (package) {
            [self.downloadedPackages addObject:package];
        }
    }
}

- (void)saveDownloadedPackages {
    NSMutableArray *saved = [NSMutableArray array];

    for (RXPackage *package in self.downloadedPackages) {
        [saved addObject:[self dictionaryFromPackage:package]];
    }

    [saved writeToURL:
        [[self radixDirectory] URLByAppendingPathComponent:@"Downloaded.plist"]
           atomically:YES];
}

- (NSDictionary *)dictionaryFromPackage:(RXPackage *)package {
    return @{
        @"name": package.name ?: @"",
        @"version": package.version ?: @"",
        @"description": package.packageDescription ?: @"",
        @"architecture": package.architecture ?: @"unknown",
        @"filename": package.filename ?: @"",
        @"dependencies": package.dependencies ?: @"",
        @"repository": package.repositoryURL ?: @"",
        @"downloadURL": package.downloadURL ?: @"",
        @"size": @(package.size)
    };
}

- (RXPackage *)packageFromDictionary:(NSDictionary *)entry {
    if (![entry isKindOfClass:NSDictionary.class] ||
        ![entry[@"name"] isKindOfClass:NSString.class] ||
        ![entry[@"version"] isKindOfClass:NSString.class]) {
        return nil;
    }

    RXPackage *package = [[RXPackage alloc] init];

    package.name = entry[@"name"];
    package.version = entry[@"version"];
    package.packageDescription = entry[@"description"] ?: @"";
    package.architecture = entry[@"architecture"] ?: @"unknown";
    package.filename = entry[@"filename"] ?: @"";
    package.dependencies = entry[@"dependencies"] ?: @"";
    package.repositoryURL = entry[@"repository"] ?: @"";
    package.downloadURL = entry[@"downloadURL"] ?: @"";
    package.size = [entry[@"size"] unsignedLongLongValue];

    return package;
}

#pragma mark - Alerts

- (void)showMessage:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:title
                                            message:message
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                             style:UIAlertActionStyleDefault
                                           handler:nil]];

    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:NO
                                                         completion:^{
            [self presentViewController:alert animated:YES completion:nil];
        }];
    } else {
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
