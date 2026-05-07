"""
Сфера Пуанкаре з анімацією еліпса поляризації
Залежності: numpy, matplotlib
"""

import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.patches import Ellipse, FancyArrowPatch
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.gridspec as gridspec

matplotlib.rcParams['toolbar'] = 'None'

# ──────────────────────────────────────────────────────────────
# Утиліти для обчислення параметрів еліпса
# ──────────────────────────────────────────────────────────────

def angles_to_stokes(psi_deg, chi_deg):
    """Кути -> точка на сфері Пуанкаре (S1, S2, S3)"""
    p, c = np.radians(psi_deg), np.radians(chi_deg)
    s1 = np.cos(2*c) * np.cos(2*p)
    s2 = np.cos(2*c) * np.sin(2*p)
    s3 = np.sin(2*c)
    return s1, s2, s3


def stokes_to_ellipse(s1, s2, s3):
    """Стокс -> параметри еліпса для малювання"""
    norm = np.sqrt(s1**2 + s2**2 + s3**2)
    norm = max(norm, 1e-9)
    psi = 0.5 * np.degrees(np.arctan2(s2, s1))
    chi = 0.5 * np.degrees(np.arcsin(np.clip(s3 / norm, -1, 1)))
    a = norm * abs(np.cos(np.radians(chi)))
    b = norm * abs(np.sin(np.radians(chi)))
    sense = np.sign(s3) if abs(s3) > 1e-6 else 0
    return psi, chi, a, b, sense


# ──────────────────────────────────────────────────────────────
# Побудова еліпса поляризації у 2D
# ──────────────────────────────────────────────────────────────

def draw_polarization_ellipse(ax, psi, chi, a, b, sense, color='orange', t=None):
    """Малює еліпс поляризації зі стрілкою обертання"""
    ax.clear()
    ax.set_aspect('equal')
    ax.set_xlim(-1.4, 1.4)
    ax.set_ylim(-1.4, 1.4)
    ax.set_facecolor('#0a0a1a')
    ax.grid(True, linestyle='--', alpha=0.2, color='#ffffff')

    # Осі
    for dx, dy, lbl in [(1.3, 0, '$X_1$'), (0, 1.3, '$X_2$')]:
        ax.annotate('', xy=(dx, dy), xytext=(-dx, -dy),
                    arrowprops=dict(arrowstyle='->', color='#aaaacc', lw=1.2))
    ax.text(1.35, 0.05, '$X_1$', color='#aaaacc', fontsize=11)
    ax.text(0.05, 1.35, '$X_2$', color='#aaaacc', fontsize=11)

    # Еліпс
    psi_r = np.radians(psi)
    theta = np.linspace(0, 2*np.pi, 300)
    x = a * np.cos(theta)
    y = b * np.sin(theta)
    xr = x * np.cos(psi_r) - y * np.sin(psi_r)
    yr = x * np.sin(psi_r) + y * np.cos(psi_r)
    ax.plot(xr, yr, color=color, lw=2, zorder=5)

    # Анімована точка на еліпсі
    if t is not None:
        phi_t = t * 2 * np.pi
        if sense < 0:
            phi_t = -phi_t
        xp = a * np.cos(phi_t)
        yp = b * np.sin(phi_t)
        xpr = xp * np.cos(psi_r) - yp * np.sin(psi_r)
        ypr = xp * np.sin(psi_r) + yp * np.cos(psi_r)
        ax.plot(xpr, ypr, 'o', color='white', markersize=7, zorder=10)
        # Промінь від центру
        ax.plot([0, xpr], [0, ypr], color=color, alpha=0.4, lw=1.2, zorder=4)

    # Стрілка обертання
    if abs(b) > 0.02 and abs(sense) > 0:
        arr_angle = np.radians(60) if sense > 0 else np.radians(-60)
        ax.annotate('', xy=(a*np.cos(arr_angle+0.3)*np.cos(psi_r) - b*np.sin(arr_angle+0.3)*np.sin(psi_r),
                             a*np.cos(arr_angle+0.3)*np.sin(psi_r) + b*np.sin(arr_angle+0.3)*np.cos(psi_r)),
                    xytext=(a*np.cos(arr_angle)*np.cos(psi_r) - b*np.sin(arr_angle)*np.sin(psi_r),
                            a*np.cos(arr_angle)*np.sin(psi_r) + b*np.sin(arr_angle)*np.cos(psi_r)),
                    arrowprops=dict(arrowstyle='->', color=color, lw=1.5))

    rot_str = 'CCW (ліва)' if sense > 0 else ('CW (права)' if sense < 0 else 'Лінійна')
    ax.set_title(
        f'Еліпс поляризації\n'
        f'$\\psi={psi:.1f}°$,  $\\chi={chi:.1f}°$   |   {rot_str}',
        color='white', fontsize=10, pad=6
    )
    ax.tick_params(colors='#666688')
    for spine in ax.spines.values():
        spine.set_color('#333355')


# ──────────────────────────────────────────────────────────────
# Побудова сфери Пуанкаре у 3D
# ──────────────────────────────────────────────────────────────

def draw_poincare_sphere(ax, s1, s2, s3, point_history=None):
    ax.clear()
    ax.set_facecolor('#07071a')

    t = np.linspace(0, 2*np.pi, 360)

    # ── Сфера: дві шари — темна заливка + легка сітка ──────────
    u = np.linspace(0, 2*np.pi, 60)
    v = np.linspace(0, np.pi, 40)
    xs = np.outer(np.cos(u), np.sin(v))
    ys = np.outer(np.sin(u), np.sin(v))
    zs = np.outer(np.ones_like(u), np.cos(v))

    # Непрозора поверхня (темно-синя, чітка)
    ax.plot_surface(xs, ys, zs, alpha=0.18,
                    color='#1a2a6c', shade=True, zorder=0,
                    lightsource=None)

    # Меридіани — 12 штук, рівномірно
    for lon in np.linspace(0, np.pi, 7):         # 0..180° (решта — симетрія)
        mx = np.cos(lon) * np.cos(t)
        my = np.sin(lon) * np.cos(t)
        mz = np.sin(t)
        ax.plot(mx, my, mz, color='#3355aa', alpha=0.55, lw=0.7, zorder=2)

    # Паралелі — 5 штук (±60°, ±30°, екватор)
    for lat_deg in [-60, -30, 0, 30, 60]:
        lat = np.radians(lat_deg)
        r = np.cos(lat)
        ax.plot(r*np.cos(t), r*np.sin(t),
                np.sin(lat)*np.ones_like(t),
                color='#3355aa', alpha=0.55, lw=0.7, zorder=2)

    # Три головні кола (ξ₁-ξ₂, ξ₁-ξ₃, ξ₂-ξ₃) — яскравіші
    ax.plot(np.cos(t), np.sin(t), np.zeros_like(t),
            color='#5577cc', alpha=0.85, lw=1.2, zorder=3)
    ax.plot(np.cos(t), np.zeros_like(t), np.sin(t),
            color='#5577cc', alpha=0.85, lw=1.2, zorder=3)
    ax.plot(np.zeros_like(t), np.cos(t), np.sin(t),
            color='#5577cc', alpha=0.85, lw=1.2, zorder=3)

    # ── Осі ────────────────────────────────────────────────────
    AXIS_LEN = 1.55
    for vec, col, lbl, off in [
        ([AXIS_LEN,0,0], '#ff7755', '$\\xi_1$', (0.12, 0.0,  0.0 )),
        ([0,AXIS_LEN,0], '#55ee88', '$\\xi_2$', (0.0,  0.12, 0.0 )),
        ([0,0,AXIS_LEN], '#5599ff', '$\\xi_3$', (0.0,  0.0,  0.12)),
    ]:
        ax.quiver(0, 0, 0, *vec, color=col, lw=2.0,
                  arrow_length_ratio=0.10, zorder=8)
        ax.text(vec[0]+off[0], vec[1]+off[1], vec[2]+off[2],
                lbl, color=col, fontsize=13, fontweight='bold', zorder=9)

    # ── Спеціальні точки ────────────────────────────────────────
    # Кожна точка: координати, колір, підпис, зміщення підпису
    special = [
        ( 1,  0,  0, '#ff9977', '$H$',  ( 0.14,  0.0,  -0.08)),
        (-1,  0,  0, '#ff9977', '$V$',  (-0.22,  0.0,  -0.08)),
        ( 0,  1,  0, '#77ffbb', '$D$',  ( 0.0,   0.14, -0.08)),
        ( 0, -1,  0, '#77ffbb', '$A$',  ( 0.04, -0.22, -0.08)),
        ( 0,  0,  1, '#77aaff', '$R$',  ( 0.06,  0.0,   0.12)),
        ( 0,  0, -1, '#77aaff', '$L$',  ( 0.06,  0.0,  -0.18)),
    ]
    for sx, sy, sz, col, lbl, dxyz in special:
        ax.scatter([sx], [sy], [sz], color=col, s=45,
                   edgecolors='white', linewidths=0.8, zorder=10)
        ax.text(sx+dxyz[0], sy+dxyz[1], sz+dxyz[2],
                lbl, color=col, fontsize=12, fontweight='bold', zorder=11)

    # ── Траєкторія ──────────────────────────────────────────────
    if point_history and len(point_history) > 1:
        ph = np.array(point_history)
        # Градієнт яскравості (старіші — прозоріші)
        n = len(ph)
        for i in range(n - 1):
            alpha = 0.15 + 0.7 * (i / n)
            ax.plot(ph[i:i+2, 0], ph[i:i+2, 1], ph[i:i+2, 2],
                    color='orange', alpha=alpha, lw=1.4, zorder=6)

    # ── Поточна точка ──────────────────────────────────────────
    # Проекційні лінії (пунктир) на три площини
    ax.plot([s1, s1], [s2, s2], [-1.3, s3],
            ':', color='orange', alpha=0.3, lw=0.9, zorder=5)
    ax.plot([s1, s1], [-1.3, s2], [s3, s3],
            ':', color='orange', alpha=0.3, lw=0.9, zorder=5)
    ax.plot([-1.3, s1], [s2, s2], [s3, s3],
            ':', color='orange', alpha=0.3, lw=0.9, zorder=5)

    # Вектор від центру
    ax.plot([0, s1], [0, s2], [0, s3],
            color='#ffcc44', alpha=0.75, lw=2.0, zorder=9)
    # Точка
    ax.scatter([s1], [s2], [s3], color='#ffaa00', s=120,
               edgecolors='white', linewidths=1.2, zorder=12)

    # ── Оформлення ─────────────────────────────────────────────
    ax.set_xlim(-1.35, 1.35)
    ax.set_ylim(-1.35, 1.35)
    ax.set_zlim(-1.35, 1.35)
    ax.set_box_aspect([1, 1, 1])
    ax.set_title('Сфера Пуанкаре', color='white', fontsize=11,
                 fontweight='bold', pad=6)
    ax.tick_params(colors='#445566', labelsize=7)
    for pane in [ax.xaxis.pane, ax.yaxis.pane, ax.zaxis.pane]:
        pane.fill = False
        pane.set_edgecolor('#1a2244')


# ──────────────────────────────────────────────────────────────
# Панель введення кутів (слайдери)
# ──────────────────────────────────────────────────────────────

def main():
    fig = plt.figure(figsize=(14, 7), facecolor='#0a0a1a')
    fig.suptitle('Сфера Пуанкаре · Поляризація світла',
                 color='white', fontsize=14, fontweight='bold', y=0.97)

    gs = gridspec.GridSpec(2, 3,
                           left=0.04, right=0.98,
                           top=0.91, bottom=0.13,
                           wspace=0.35, hspace=0.45)

    ax3d  = fig.add_subplot(gs[:, 0], projection='3d')
    ax2d  = fig.add_subplot(gs[:, 1])
    ax_psi = fig.add_subplot(gs[0, 2])
    ax_chi = fig.add_subplot(gs[1, 2])

    ax3d.set_facecolor('#0a0a1a')
    ax2d.set_facecolor('#0a0a1a')
    for a in [ax_psi, ax_chi]:
        a.set_facecolor('#0a0a1a')

    # Слайдери
    from matplotlib.widgets import Slider, Button

    ax_sl_psi = fig.add_axes([0.68, 0.55, 0.28, 0.03], facecolor='#1a1a2e')
    ax_sl_chi = fig.add_axes([0.68, 0.44, 0.28, 0.03], facecolor='#1a1a2e')

    sl_psi = Slider(ax_sl_psi, '$\\psi$ (°)', -90, 90, valinit=45,
                    color='#ff8844', initcolor='none')
    sl_chi = Slider(ax_sl_chi, '$\\chi$ (°)', -45, 45, valinit=15,
                    color='#44aaff', initcolor='none')
    for sl in [sl_psi, sl_chi]:
        sl.label.set_color('white')
        sl.valtext.set_color('white')

    # Кнопка анімації
    ax_btn = fig.add_axes([0.68, 0.33, 0.12, 0.05], facecolor='#1a1a2e')
    btn = Button(ax_btn, '▶ Старт', color='#223355', hovercolor='#334466')
    btn.label.set_color('white')

    ax_btn_stop = fig.add_axes([0.84, 0.33, 0.12, 0.05], facecolor='#1a1a2e')
    btn_stop = Button(ax_btn_stop, '■ Стоп', color='#332222', hovercolor='#443333')
    btn_stop.label.set_color('white')

    # Текстова панель
    ax_info = fig.add_axes([0.68, 0.15, 0.28, 0.16], facecolor='#0d0d20')
    ax_info.set_xticks([]); ax_info.set_yticks([])
    for spine in ax_info.spines.values():
        spine.set_color('#334466')
    info_text = ax_info.text(0.05, 0.85, '', transform=ax_info.transAxes,
                              color='#aaccff', fontsize=9.5,
                              verticalalignment='top', fontfamily='monospace')

    # Стан
    state = {'t': 0.0, 'running': False, 'history': []}

    def update_info(psi, chi, s1, s2, s3):
        rot = 'CCW ←' if s3 > 1e-4 else ('CW →' if s3 < -1e-4 else 'Лінійна')
        info_text.set_text(
            f'ψ = {psi:+7.2f}°\n'
            f'χ = {chi:+7.2f}°\n'
            f'S₁= {s1:+.4f}\n'
            f'S₂= {s2:+.4f}\n'
            f'S₃= {s3:+.4f}\n'
            f'Обертання: {rot}'
        )

    def refresh(t_val=None):
        psi = sl_psi.val
        chi = sl_chi.val
        s1, s2, s3 = angles_to_stokes(psi, chi)
        psi_e, chi_e, a, b, sense = stokes_to_ellipse(s1, s2, s3)

        draw_polarization_ellipse(ax2d, psi_e, chi_e, a, b, sense,
                                  color='orange', t=t_val)
        draw_poincare_sphere(ax3d, s1, s2, s3,
                             point_history=state['history'])
        update_info(psi, chi, s1, s2, s3)

        # Мінімальний графік на ax_psi / ax_chi (дугові індикатори)
        for ax_ind, val, lim, label, color in [
            (ax_psi, psi, 90, '$\\psi$', '#ff8844'),
            (ax_chi, chi, 45, '$\\chi$', '#44aaff'),
        ]:
            ax_ind.clear()
            ax_ind.set_facecolor('#0a0a1a')
            theta_arc = np.linspace(-np.pi/2, np.pi/2, 200)
            ax_ind.plot(np.cos(theta_arc), np.sin(theta_arc),
                        color='#333355', lw=8, solid_capstyle='round')
            frac = val / lim  # -1..1
            t0 = -np.pi/2
            t1 = t0 + frac * np.pi
            if abs(frac) > 0.01:
                arc = np.linspace(t0, t1, 100)
                ax_ind.plot(np.cos(arc), np.sin(arc), color=color, lw=8,
                            solid_capstyle='round', alpha=0.9)
            ax_ind.text(0, -0.25, f'{label} = {val:.1f}°',
                        ha='center', color='white', fontsize=10)
            ax_ind.set_xlim(-1.3, 1.3); ax_ind.set_ylim(-0.5, 1.3)
            ax_ind.set_aspect('equal'); ax_ind.axis('off')

        fig.canvas.draw_idle()

    def animate(frame):
        if state['running']:
            state['t'] = (state['t'] + 0.008) % 1.0
            refresh(t_val=state['t'])

    def on_slider_change(val):
        psi = sl_psi.val; chi = sl_chi.val
        s1, s2, s3 = angles_to_stokes(psi, chi)
        state['history'].append((s1, s2, s3))
        if len(state['history']) > 120:
            state['history'].pop(0)
        refresh(t_val=state['t'] if state['running'] else None)

    def on_start(event):
        state['running'] = True

    def on_stop(event):
        state['running'] = False
        refresh(t_val=None)

    sl_psi.on_changed(on_slider_change)
    sl_chi.on_changed(on_slider_change)
    btn.on_clicked(on_start)
    btn_stop.on_clicked(on_stop)

    # Початковий рендер
    refresh()

    ani = animation.FuncAnimation(fig, animate, interval=40, cache_frame_data=False)

    plt.show()


if __name__ == '__main__':
    main()
