<script setup lang="ts">
import { gsap } from "gsap";
import { Physics2DPlugin } from "gsap/Physics2DPlugin";

gsap.registerPlugin(Physics2DPlugin);

const gridRef = ref<HTMLElement | null>(null);
const rows = ref<HTMLElement[]>([]);
const cells = ref<HTMLElement[]>([]);

let clicked = false;
let reset_all = false;
const pull_distance = 70;

const updateCellPositions = () => {
	cells.value.forEach((cell) => {
		const rect = cell.getBoundingClientRect();
		(cell as any).center_position = {
			x: (rect.left + rect.right) / 2,
			y: (rect.top + rect.bottom) / 2,
		};
	});
};

const handleCellClick = (e: PointerEvent, i: number) => {
	if (clicked) return;
	clicked = true;
	gsap.to(".cell", {
		duration: 1.6,
		physics2D: {
			velocity: "random(400, 1000)",
			angle: "random(250, 290)",
			gravity: 2000,
		},
		stagger: {
			grid: [rows.value.length, rows.value[0].children.length],
			from: i,
			amount: 0.3,
		},
		onComplete() {
			this.timeScale(-1.3);
		},
		onReverseComplete: () => {
			clicked = false;
			reset_all = true;
			handlePointerMove();
		},
	});
};

const handlePointerMove = (
	e: PointerEvent | { pageX: number; pageY: number } = {
		pageX: -pull_distance,
		pageY: -pull_distance,
	}
) => {
	if (clicked) return;
	const { pageX: px, pageY: py } = e;
	cells.value.forEach((cell) => {
		const center = (cell as any).center_position as { x: number; y: number };
		const dx = px - center.x;
		const dy = py - center.y;
		const dist = Math.hypot(dx, dy);
		if (dist < pull_distance) {
			const pct = dist / pull_distance;
			(cell as any).pulled = true;
			gsap.to(cell, { duration: 0.2, x: dx * pct, y: dy * pct });
		} else {
			if (!(cell as any).pulled) return;
			(cell as any).pulled = false;
			gsap.to(cell, { duration: 1, x: 0, y: 0, ease: "elastic.out(1, 0.3)" });
		}
	});
	if (reset_all) {
		reset_all = false;
		gsap.to(cells.value, { duration: 1, x: 0, y: 0, ease: "elastic.out(1, 0.3)" });
	}
};

const resizeHandler = updateCellPositions;
const pointerMoveHandler = handlePointerMove;
const pointerLeaveHandler = () => handlePointerMove();

onMounted(async () => {
	await nextTick();
	if (!gridRef.value) return;
	rows.value = Array.from(gridRef.value.querySelectorAll(".row"));
	cells.value = Array.from(gridRef.value.querySelectorAll(".cell"));
	updateCellPositions();
	window.addEventListener("resize", resizeHandler);
	window.addEventListener("pointermove", pointerMoveHandler);
	document.body.addEventListener("pointerleave", pointerLeaveHandler);
	cells.value.forEach((cell, i) =>
		cell.addEventListener("pointerup", (e) => handleCellClick(e as PointerEvent, i))
	);
});

onUnmounted(() => {
	window.removeEventListener("resize", resizeHandler);
	window.removeEventListener("pointermove", pointerMoveHandler);
	document.body.removeEventListener("pointerleave", pointerLeaveHandler);
	cells.value.forEach((cell, i) =>
		cell.removeEventListener("pointerup", (e) => handleCellClick(e as PointerEvent, i))
	);
});
</script>

<template>
	<div class="grid" ref="gridRef">
		<div v-for="x in 11" :key="x" class="row">
			<div v-for="y in 11" :key="y" class="cell" :data-x="x - 1" :data-y="y - 1" />
		</div>
	</div>
</template>

<style>
body {
	display: grid;
	justify-content: center;
	align-content: center;
	background-color: #0e100f;
	height: 100svh;
	margin: 0;
	overflow: hidden;
	user-select: none;
}

.grid {
	--gap: 12px;
	display: flex;
	flex-direction: column;
	gap: var(--gap);
}

.row {
	display: flex;
	gap: var(--gap);
}

.cell {
	--size: 24px;
	width: var(--size);
	height: var(--size);
	background-color: #fffce1;
	border-radius: 50%;
	will-change: transform;
	cursor: pointer;
}
</style>
