<script lang="ts">
	import type { SplitContainer, Window } from 'glazewm';
	import { onMount } from 'svelte';
	import type {
		BatteryOutput,
		DateOutput,
		GlazeWmOutput,
		NetworkOutput,
		WeatherOutput
	} from 'zebar';
	import * as zebar from 'zebar';

	let battery = $state<BatteryOutput | null>();
	let date = $state<DateOutput | null>();
	let glazewm = $state<GlazeWmOutput | null>();
	let network = $state<NetworkOutput | null>();
	let weather = $state<WeatherOutput | null>();

	onMount(() => {
		const providers = zebar.createProviderGroup({
			battery: { type: 'battery' },
			date: { type: 'date', formatting: 'dd LLL HH:mm' },
			glazewm: { type: 'glazewm' },
			network: { type: 'network' },
			weather: { type: 'weather', latitude: -39, longitude: -62 }
		});

		providers.onOutput(() => {
			battery = providers.outputMap.battery;
			date = providers.outputMap.date;
			glazewm = providers.outputMap.glazewm;
			network = providers.outputMap.network;
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

	const apps_icons = {
		default: '󰘔',
		vivaldi: '󰖟 ',
		firefox: '󰖟 ',
		chrome: '󰖟 ',
		windowsterminal: ' ',
		wezterm: ' ',
		webview: '󰜏 ',
		code: ' ',
		explorer: ' ',
		sumatra: '',
		discord: '󰙯',
		spotify: '',
		cbase: '󰡗',
		scid: '󰡗',
		chess: '󰡗',
		zoom: '',
		thunderbird: '󰇮',
		taskmgr: '',
		soffice: '', // TODO: use different icons for writer, calc, etc.
		winword: '',
		excel: '',
		powerpnt: ''
	};

	function getIcons(children: (SplitContainer | Window)[]): string[] {
		let icons: string[] = [];
		for (const child of children) {
			if (child.type === 'split') {
				const i = getIcons(child.children);
				icons = icons.concat(i);
			} else {
				const app = (Object.keys(apps_icons) as Array<keyof typeof apps_icons>).find((win) =>
					child.processName.toLowerCase().includes(win)
				);
				if (app) {
					icons.push(apps_icons[app]);
				} else {
					icons.push(apps_icons['default']);
				}
			}
		}
		return icons;
	}

	function getWorkspaceIcons(children: (SplitContainer | Window)[]): string {
		const icons = getIcons(children);
		if (icons.length > 0) {
			return ': ' + icons.join(' ');
		}
		return '';
	}
</script>

<div class="flex h-full items-center justify-between px-4">
	<div class="flex">
		<!-- <button -->
		<!-- 	aria-label="tiling-direction" -->
		<!-- 	type="button" -->
		<!-- 	class="chip-icon mr-4 h-fit py-0 preset-outlined-primary-500" -->
		<!-- 	onclick={() => glazewm!.runCommand('toggle-tiling-direction')} -->
		<!-- > -->
		<!-- 	{glazewm?.tilingDirection[0].toUpperCase()} -->
		<!-- </button> -->
		{#if glazewm}
			{console.log(glazewm.currentWorkspaces)}
			{#each glazewm.currentWorkspaces as workspace}
				{#if workspace.children.length !== 0 || workspace.hasFocus}
					<button
						type="button"
						class="chip h-fit py-0 {workspace.hasFocus
							? 'preset-filled-primary-500'
							: 'preset-outlined-primary-500'} {workspace.children.length !== 0 ? 'pr-5' : ''}"
						onclick={() => glazewm?.runCommand('focus --workspace ' + workspace.name)}
						>{workspace.name + getWorkspaceIcons(workspace.children)}</button
					>
				{/if}
			{/each}
		{/if}
	</div>
	<!-- <div class="flex gap-4 justify-self-end"> -->
	<!-- 	{#if weather} -->
	<!-- 		<div class="badge h-fit py-0 preset-tonal-secondary"> -->
	<!-- 			{weather_icons[weather.status]}&nbsp; -->
	<!-- 			{Math.round(weather.celsiusTemp)}° -->
	<!-- 		</div> -->
	<!-- 	{/if} -->
	<!-- 	{#if network} -->
	<!-- 		<div -->
	<!-- 			class="badge-icon h-fit preset-tonal-secondary {network.defaultInterface?.type == 'wifi' -->
	<!-- 				? 'pr-1' -->
	<!-- 				: 'pr-1'}" -->
	<!-- 		> -->
	<!-- 			{#if network.defaultInterface?.type == 'ethernet'} -->
	<!-- 				󰱓 -->
	<!-- 			{:else if network.defaultInterface?.type == 'wifi' && network.defaultGateway} -->
	<!-- 				{#if (network.defaultGateway.signalStrength = 0)} -->
	<!-- 					󰤯 -->
	<!-- 				{:else if network.defaultGateway.signalStrength <= 25} -->
	<!-- 					󰤟 -->
	<!-- 				{:else if network.defaultGateway.signalStrength <= 50} -->
	<!-- 					󰤢 -->
	<!-- 				{:else if network.defaultGateway.signalStrength <= 75} -->
	<!-- 					󰤥 -->
	<!-- 				{:else} -->
	<!-- 					󰤨 -->
	<!-- 				{/if} -->
	<!-- 			{:else} -->
	<!-- 				󰛵 -->
	<!-- 			{/if} -->
	<!-- 		</div> -->
	<!-- 		{#if network.defaultInterface?.type == 'wifi'} -->
	<!-- 			<div> -->
	<!-- 				{network.defaultGateway?.signalStrength} -->
	<!-- 			</div> -->
	<!-- 		{/if} -->
	<!-- 	{:else} -->
	<!-- 		<div class="badge-icon h-fit pr-1 preset-tonal-secondary">󰅛</div> -->
	<!-- 	{/if} -->
	<!-- 	{#if battery} -->
	<!-- 		<div class="badge h-fit py-0 preset-tonal-secondary"> -->
	<!-- 			{battery.chargePercent} -->
	<!-- 		</div> -->
	<!-- 	{/if} -->
	<!-- 	{#if date} -->
	<!-- 		<div class="badge h-fit py-0 preset-tonal-secondary"> -->
	<!-- 			{date.formatted} -->
	<!-- 		</div> -->
	<!-- 	{/if} -->
	<!-- </div> -->
</div>
