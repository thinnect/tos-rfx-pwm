/**
 * @author Raido Pahtma
 * @license MIT
 */
interface GeneralPWM {

	/**
	 * @param frequency Counter frequency, Hz.
	 * @param mode Module operating mode, normal/fast/phase-correct etc.
	 *             Some modes may be platform dependant.
	 */
	async command error_t configure(uint32_t frequency, uint8_t mode);

	/**
	 * Get the actual frequency, may differ from value given to configure.
	 */
	async command uint32_t getFrequency();

	/**
	 * Get the current mode of operation.
	 */
	async command uint8_t getMode();

	/**
	 * @param period Number of ticks before counter reset,
	 *               may not be applicable in all modes (returns EINVAL).
	 */
	async command error_t setPeriod(uint16_t period);

	/**
	 * Number of ticks befor counter reset.
	 */
	async command uint16_t getPeriod();

	/**
	 * @param channel Channel number.
	 * @param match Output compare match value for the channel. Duty cycle is 100 * (match / period).
	 * @param invert Invert PWM output.
	 */
	async command error_t start(uint8_t channel, uint16_t match, bool invert);

	/**
	 * @param channel Channel number.
	 */
	async command error_t stop(uint8_t channel);

}
