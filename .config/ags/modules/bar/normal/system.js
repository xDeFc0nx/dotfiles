import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Label, Button, Overlay, Revealer, Scrollable, Stack, EventBox } = Widget;
const { exec, execAsync } = Utils;
const { GLib } = imports.gi;
import Battery from 'resource:///com/github/Aylur/ags/service/battery.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { AnimatedCircProg } from "../../.commonwidgets/cairo_circularprogress.js";
import { WWO_CODE, WEATHER_SYMBOL, NIGHT_WEATHER_SYMBOL } from '../../.commondata/weather.js';

const WEATHER_CACHE_FOLDER = `${GLib.get_user_cache_dir()}/ags/weather`;
Utils.exec(`mkdir -p ${WEATHER_CACHE_FOLDER}`);

// Fetch Wakapi coding time data
const fetchWakapiCodingTime = async () => {
    try {
        const response = await execAsync([
            'curl', '-X', 'GET',
            'https://wakapi.dev/api/users/xDeFc0nx/statusbar/today',
            '-H', 'accept: application/json',
            '-H', 'Authorization: Basic YTExNWU1OTgtNjg5Zi00YzAxLTk3YzctZDU4ZTFmNzQ3MmFm'
        ]);
        
        const data = JSON.parse(response);
        const codingTime = data.data.grand_total.text; // Example: "4 hrs 36 mins"
        return codingTime; // Return the coding time
    } catch (error) {
        console.error("Error fetching Wakapi data: ", error);
        return "Error"; // In case of an error, return an error string
    }
};

// Variable for displaying coding time, updated on a polling interval
const codingTime = Variable('', {
    poll: [
        userOptions.time.interval, // Set polling interval here (e.g., every minute)
        async () => {
            const time = await fetchWakapiCodingTime();
            return `${time}`; // Return the fetched time
        }
    ]
});

// Bar section for Wakapi coding time
const BarWakapi = () => Box({
    className: 'spacing-h-4 bar-wakapi-time-box',
    children: [
          MaterialIcon('code', 'norm', { tooltipText: "Coding Time" }), // Add icon here
    
        Widget.Label({
            className: 'txt-smallie',
            label: codingTime.bind(), // Bind the coding time variable
        }),
    ]
});

// Bar group to hold Wakapi time in the bar
const BarGroup = ({ child }) => Widget.Box({
    className: 'bar-group-margin bar-sides',
    children: [
        Widget.Box({
            className: 'bar-group bar-group-standalone bar-group-pad-system',
            children: [child],
        }),
    ]
});

// Bar section for battery progress


// Bar section for the clock
const time = Variable('', {
    poll: [
        userOptions.time.interval,
        () => GLib.DateTime.new_now_local().format(userOptions.time.format),
    ],
})

const date = Variable('', {
    poll: [
        userOptions.time.dateInterval,
        () => GLib.DateTime.new_now_local().format(userOptions.time.dateFormatLong),
    ],
})

const BarClock = () => Widget.Box({
    vpack: 'center',
    className: 'spacing-h-4 bar-clock-box',
    children: [
        Widget.Label({
            className: 'bar-time',
            label: time.bind(),
        }),
        Widget.Label({
            className: 'txt-norm txt-onLayer1',
            label: '•',
        }),
        Widget.Label({
            className: 'txt-smallie bar-date',
            label: date.bind(),
        }),
    ],
});

// Main widget for the bar, incorporating the Wakapi section and other components
export default () => Widget.EventBox({
    onScrollUp: (self) => switchToRelativeWorkspace(self, -1),
    onScrollDown: (self) => switchToRelativeWorkspace(self, +1),
    onPrimaryClick: () => App.toggleWindow('sideright'),
    child: Widget.Box({
        className: 'spacing-h-4',
        children: [
            BarGroup({ child: BarClock() }), // Add clock to the bar
            BarGroup({ child: BarWakapi() }), // Add Wakapi coding stats to the bar
        ]
    })
});

// Battery section setup
const BarBattery = () => Box({
    className: 'spacing-h-4 bar-batt-txt',
    children: [
        Revealer({
            transitionDuration: userOptions.animations.durationSmall,
            revealChild: false,
            transition: 'slide_right',
            child: MaterialIcon('bolt', 'norm', { tooltipText: "Charging" }),
            setup: (self) => self.hook(Battery, revealer => {
                self.revealChild = Battery.charging;
            }),
        }),
        Label({
            className: 'txt-smallie',
            setup: (self) => self.hook(Battery, label => {
                label.label = `${Number.parseFloat(Battery.percent.toFixed(1))}%`;
            }),
        }),
        Overlay({
            child: Widget.Box({
                vpack: 'center',
                className: 'bar-batt',
                homogeneous: true,
                children: [
                    MaterialIcon('battery_full', 'small'),
                ],
                setup: (self) => self.hook(Battery, box => {
                    box.toggleClassName('bar-batt-low', Battery.percent <= userOptions.battery.low);
                    box.toggleClassName('bar-batt-full', Battery.charged);
                }),
            }),
            overlays: [
                BarBatteryProgress(),
            ]
        }),
    ]
});

// Grouping the Bar section
// Utility button setup
const UtilButton = ({ name, icon, onClicked }) => Button({
    vpack: 'center',
    tooltipText: name,
    onClicked: onClicked,
    className: 'bar-util-btn icon-material txt-norm',
    label: `${icon}`,
});

const Utilities = () => Box({
    hpack: 'center',
    className: 'spacing-h-4',
    children: [
        UtilButton({
            name: getString('Screen snip'), icon: 'screenshot_region', onClicked: () => {
                Utils.execAsync(`${App.configDir}/scripts/grimblast.sh copy area`)
                    .catch(print)
            }
        }),
        UtilButton({
            name: getString('Color picker'), icon: 'colorize', onClicked: () => {
                Utils.execAsync(['hyprpicker', '-a']).catch(print)
            }
        }),
        UtilButton({
            name: getString('Toggle on-screen keyboard'), icon: 'keyboard', onClicked: () => {
                toggleWindowOnAllMonitors('osk');
            }
        }),
    ]
});

// Battery module section setup
const BatteryModule = () => Stack({
    transition: 'slide_up_down',
    transitionDuration: userOptions.animations.durationLarge,
    children: {
        'laptop': Box({
            className: 'spacing-h-4', children: [
                BarGroup({ child: Utilities() }),
                BarGroup({ child: BarBattery() }),
            ]
        }),
        'desktop': BarGroup({
            child: Box({
                hexpand: true,
                hpack: 'center',
                className: 'spacing-h-4 txt-onSurfaceVariant',
                children: [
                    MaterialIcon('device_thermostat', 'small'),
                    Label({
                        label: 'Weather',
                    })
                ],
                setup: (self) => self.poll(900000, async (self) => {
                    const WEATHER_CACHE_PATH = WEATHER_CACHE_FOLDER + '/wttr.in.txt';
                    const updateWeatherForCity = (city) => execAsync(`curl https://wttr.in/${city.replace(/ /g, '%20')}?format=j1`)
                        .then(output => {
                            const weather = JSON.parse(output);
                            Utils.writeFile(JSON.stringify(weather), WEATHER_CACHE_PATH)
                                .catch(print);
                            const weatherCode = weather.current_condition[0].weatherCode;
                            const weatherDesc = weather.current_condition[0].weatherDesc[0].value;
                            const temperature = weather.current_condition[0][`temp_${userOptions.weather.preferredUnit}`];
                            const feelsLike = weather.current_condition[0][`FeelsLike${userOptions.weather.preferredUnit}`];
                            const weatherSymbol = WEATHER_SYMBOL[WWO_CODE[weatherCode]];
                            self.children[0].label = weatherSymbol;
                            self.children[1].label = `${temperature}°${userOptions.weather.preferredUnit} • Feels like ${feelsLike}°${userOptions.weather.preferredUnit}`;
                            self.tooltipText = weatherDesc;
                        }).catch((err) => {
                            try { // Read from cache
                                const weather = JSON.parse(
                                    Utils.readFile(WEATHER_CACHE_PATH)
                                );
                                const weatherCode = weather.current_condition[0].weatherCode;
                                const weatherDesc = weather.current_condition[0].weatherDesc[0].value;
                                const temperature = weather.current_condition[0][`temp_${userOptions.weather.preferredUnit}`];
                                const feelsLike = weather.current_condition[0][`FeelsLike${userOptions.weather.preferredUnit}`];
                                const weatherSymbol = WEATHER_SYMBOL[WWO_CODE[weatherCode]];
                                self.children[0].label = weatherSymbol;
                                self.children[1].label = `${temperature}°${userOptions.weather.preferredUnit} • Feels like ${feelsLike}°${userOptions.weather.preferredUnit}`;
                                self.tooltipText = weatherDesc;
                            } catch (err) {
                                self.tooltipText = "Weather data unavailable";
                                self.children[1].label = "Check internet connection";
                            }
                        })
                }),
            })
        }),
    }
});
