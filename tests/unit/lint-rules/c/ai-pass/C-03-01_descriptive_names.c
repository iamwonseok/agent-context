/* C-03-01: Use descriptive names for globals and functions (PASS) */
/* AI Review: Names clearly describe their purpose */

#include <stdio.h>
#include <stdbool.h>

/* Global: Name clearly indicates purpose */
static int connection_retry_count = 0;
static bool is_network_connected = false;

/**
 * Attempt to establish network connection
 * @return 0 on success, negative on failure
 */
int establish_network_connection(void)
{
	/* Local variables can use conventional short names */
	int ret = 0;
	int i;

	for (i = 0; i < 3; i++) {
		connection_retry_count++;
		/* ... connection logic ... */
	}

	is_network_connected = true;
	return ret;
}

/**
 * Check if network is currently connected
 * @return true if connected, false otherwise
 */
bool check_network_status(void)
{
	return is_network_connected;
}
