/* See LICENSE file for copyright and license details. */

/* interval between updates (in ms) */
#include <stdlib.h>
const unsigned int interval = 1000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "n/a";

/* maximum output string length */
#define MAXLEN 2048

static const struct arg args[] = {

    /* function format          argument */
    {run_command, "[ %s]", "pacupdate"},
    {netspeed_rx, "[ %sB/s]   ", "wlp2s0"},
    {cpu_perc, "[ %s%%]  ", NULL},
    {ram_perc, "[ %s%%]   ", NULL},
    {datetime, "%s", "%a %b %d %R"},
};
