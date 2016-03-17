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
	 * @param channel Channel number.
	 * @param duty_cycle PWM duty cycle, 0-100.
	 * @param invert Invert PWM output.
	 */
	async command error_t start(uint8_t channel, uint8_t duty_cycle, bool invert);

	/**
	 * @param channel Channel number.
	 */
	async command error_t stop(uint8_t channel);

}
