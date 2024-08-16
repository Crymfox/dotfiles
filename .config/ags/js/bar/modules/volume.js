import Audio from 'resource:///com/github/Aylur/ags/service/audio.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Stack, Icon, Slider, Revealer, EventBox } = Widget;

const VolumeIcon = () => Box({
  className: 'volIcon',
    children: [
      Stack({
        children: {
          '101': Icon('audio-volume-overamplified-symbolic'),
          '67': Icon('audio-volume-high-symbolic'),
          '34': Icon('audio-volume-medium-symbolic'),
          '1':  Icon('audio-volume-low-symbolic'),
          '0':  Icon('audio-volume-muted-symbolic'),
        },
      }).hook(Audio, self => {
          if (!Audio.speaker)
              return;

          if (Audio.speaker.is_muted) {
            self.shown = '0';
            return;
          }

          const show = [101, 67, 34, 1, 0].find(
            threshold => threshold <= Audio.speaker.volume * 100);

            self.shown = `${show}`;
        }, 'speaker-changed'),
    ],
});

// on fn + arrow left/right, change volume

const PercentBar = () => Revealer({
  transition: 'slide_right',
  revealChild: false,
  child: Slider({
    className: 'volBar',
    hexpand: true,
    drawValue: false,
    onChange: ({ value }) => Audio.speaker.volume = value,
    value: Audio.speaker.bind('volume'),
  }).hook(Audio, self => {
      if (!Audio.speaker)
        return

        self.value = Audio.speaker.volume
    }, "speaker-changed"),
});

const percentBar = PercentBar();

const Volume = () => EventBox({
  className: 'volume',
  onHover: () => percentBar.reveal_child = true,
  onHoverLost: (widget, event) => {
    const [_, x, y] = event.get_coords()
    const w = widget.get_allocation().width;
    const h = widget.get_allocation().height;
    if (x < 0 || x > w || y < 0 || y > h) {
      percentBar.reveal_child = false
    }
  },
  // connections: [[Audio, box => {box.set_tooltip_text(`${String(Math.floor(Audio.speaker.volume * 100))}%`)}, 'speaker-changed']],
  child: Box({
    children: [
      VolumeIcon(),
      percentBar
    ]
  }),
});


// const keybindings = {
//   'XF86AudioRaiseVolume': () => Audio.speaker.volume += 0.05,
//   'XF86AudioLowerVolume': () => Audio.speaker.volume -= 0.05,
//   'XF86AudioMute': () => Audio.speaker.is_muted = !Audio.speaker.is_muted,
// };

// const keybinding = (key, fn) => global.display.add_keybinding(
//   key,
//   keybindings[key],
// );

// const keys = Object.keys(keybindings).map(key => keybinding(key, keybindings[key]));

// Volume.destroy = () => keys.forEach(key => global.display.remove_keybinding(key));

export default Volume;
