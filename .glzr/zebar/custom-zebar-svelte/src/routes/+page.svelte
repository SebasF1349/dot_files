<script lang="ts">
	import { onMount } from 'svelte';
	import type {
		BatteryOutput,
		DateOutput,
		GlazeWmOutput,
		// NetworkOutput,
		WeatherOutput
	} from 'zebar';
	import * as zebar from 'zebar';

	let battery = $state<BatteryOutput | null>();
	let date = $state<DateOutput | null>();
	let glazewm = $state<GlazeWmOutput | null>();
	// let network = $state<NetworkOutput | null>();
	let weather = $state<WeatherOutput | null>();

	onMount(() => {
		const providers = zebar.createProviderGroup({
			battery: { type: 'battery' },
			date: { type: 'date', formatting: 'dd LLL HH:mm' },
			glazewm: { type: 'glazewm' },
			// network: { type: 'network' },
			weather: { type: 'weather', latitude: -39, longitude: -62 }
		});

		providers.onOutput(() => {
			battery = providers.outputMap.battery;
			date = providers.outputMap.date;
			glazewm = providers.outputMap.glazewm;
			// network = providers.outputMap.network;
			weather = providers.outputMap.weather;
		});
	});

	const weather_icons = {
		clear_day: '',
		clear_night: '',
		cloudy_day: '',
		cloudy_night: '',
		light_rain_day: '',
		light_rain_night: '',
		heavy_rain_day: '',
		heavy_rain_night: '',
		snow_day: '',
		snow_night: '',
		thunder_day: '',
		thunder_night: ' '
	};
</script>

<div class="flex h-full items-center justify-between px-4">
	<div class="flex">
		<button
			aria-label="tiling-direction"
			type="button"
			class="chip-icon mr-4 h-fit py-0 preset-outlined-primary-500"
			onclick={() => glazewm!.runCommand('toggle-tiling-direction')}
		>
			{glazewm?.tilingDirection[0].toUpperCase()}
		</button>
		{#if glazewm}
			{#each glazewm.currentWorkspaces as workspace, i}
				<button
					type="button"
					class="chip h-fit py-0 {workspace.hasFocus
						? 'preset-filled-primary-500'
						: 'preset-outlined-primary-500'}"
					onclick={() => glazewm?.runCommand('focus --workspace ' + (i + 1))}>{i + 1}</button
				>
			{/each}
		{/if}
	</div>
	<div class="flex gap-4 justify-self-end">
		{#if weather}
			<div class="badge py-0 preset-filled">
				{weather_icons[weather.status]}&nbsp;
				{Math.round(weather.celsiusTemp)}°
			</div>
		{/if}
		<!-- {#if network}
			<div
				class="badge-icon preset-filled {network.defaultInterface?.type == 'wifi'
					? 'pr-1'
					: 'pr-1'}"
			>
				{#if network.defaultInterface?.type == 'ethernet'}
					󰈀
				{:else if network.defaultInterface?.type == 'wifi' && network.defaultGateway}
					{#if (network.defaultGateway.signalStrength = 0)}
						󰤯
					{:else if network.defaultGateway.signalStrength <= 25}
						󰤟
					{:else if network.defaultGateway.signalStrength <= 50}
						󰤢
					{:else if network.defaultGateway.signalStrength <= 75}
						󰤥
					{:else}
						󰤨
					{/if}
				{/if}
			</div>
			{#if network.defaultInterface?.type == 'wifi'}
				<div>
					{network.defaultGateway?.signalStrength}
				</div>
			{/if}
		{/if} -->
		{#if battery}
			<div class="badge py-0 preset-filled">
				{battery.chargePercent}
			</div>
		{/if}
		{#if date}
			<div class="badge py-0 preset-filled">
				{date.formatted}
			</div>
		{/if}
	</div>
</div>
