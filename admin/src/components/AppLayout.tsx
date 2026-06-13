import React, { useState, useRef, useEffect } from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/auth.store';
import {
  LayoutDashboard, Users, Map, Star, Trophy, ArrowLeftRight,
  Building, LogOut, PanelLeftClose, PanelLeft, ChevronDown, BookOpen,
} from 'lucide-react';
import { Button } from './ui/button';

export const AppLayout: React.FC = () => {
  const { admin, logout } = useAuthStore();
  const [collapsed, setCollapsed] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);

  // Close profile dropdown on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) setProfileOpen(false);
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  const navLinks = [
    { to: "/", icon: <LayoutDashboard size={20} />, label: "Dashboard" },
    { to: "/trails", icon: <Map size={20} />, label: "Trilhas" },
    { to: "/characters", icon: <Star size={20} />, label: "Personagens" },
    { to: "/achievements", icon: <Trophy size={20} />, label: "Conquistas / Missões" },
    { to: "/leagues", icon: <ArrowLeftRight size={20} />, label: "Ligas" },
    { to: "/studies", icon: <BookOpen size={20} />, label: "Estudos IA" },
    { to: "/companies", icon: <Building size={20} />, label: "Instituições" },
    { to: "/users", icon: <Users size={20} />, label: "Usuários" },
  ];

  return (
    <div className="flex h-screen bg-gray-100 dark:bg-zinc-900">
      <aside className={`${collapsed ? 'w-[68px]' : 'w-64'} bg-white dark:bg-zinc-950 border-r border-gray-200 dark:border-zinc-800 flex flex-col transition-all duration-200 ease-in-out`}>
        {/* Header */}
        <div className="h-16 flex items-center justify-between border-b border-gray-200 dark:border-zinc-800 px-3">
          {!collapsed && (
            <h1 className="text-lg font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent whitespace-nowrap">
              JourneyFaith Admin
            </h1>
          )}
          <button
            onClick={() => setCollapsed(!collapsed)}
            className="p-1.5 rounded-md hover:bg-gray-100 dark:hover:bg-zinc-800 text-gray-500 transition-colors mx-auto"
            title={collapsed ? 'Expandir menu' : 'Recolher menu'}
          >
            {collapsed ? <PanelLeft size={18} /> : <PanelLeftClose size={18} />}
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 p-2 space-y-1 overflow-y-auto">
          {navLinks.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              end={link.to === '/'}
              title={collapsed ? link.label : undefined}
              className={({ isActive }) =>
                `flex items-center gap-3 px-3 py-2 rounded-md transition-colors ${
                  collapsed ? 'justify-center' : ''
                } ${
                  isActive
                    ? "bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400 font-medium"
                    : "text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-zinc-800"
                }`
              }
            >
              {link.icon}
              {!collapsed && <span className="whitespace-nowrap">{link.label}</span>}
            </NavLink>
          ))}
        </nav>
      </aside>

      <main className="flex-1 flex flex-col overflow-hidden">
        <header className="h-16 bg-white dark:bg-zinc-950 border-b border-gray-100 dark:border-zinc-800 flex items-center justify-between px-8 backdrop-blur-md bg-white/80">
          <h2 className="font-black italic text-lg text-slate-800 uppercase tracking-tighter">Command Center</h2>

          {/* Profile area */}
          <div className="relative" ref={profileRef}>
            <button
              onClick={() => setProfileOpen(!profileOpen)}
              className="flex items-center gap-3 hover:bg-slate-50 rounded-xl px-3 py-1.5 transition-colors"
            >
              <div className="flex flex-col items-end">
                <span className="text-[10px] font-black uppercase text-slate-400 leading-none">Operador</span>
                <strong className="text-sm text-slate-700 italic">{admin?.name}</strong>
              </div>
              <div className="w-10 h-10 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600 flex items-center justify-center font-black text-white text-sm shadow-sm">
                {admin?.name?.[0] || 'A'}
              </div>
              <ChevronDown size={14} className={`text-slate-400 transition-transform ${profileOpen ? 'rotate-180' : ''}`} />
            </button>

            {/* Profile Dropdown */}
            {profileOpen && (
              <div className="absolute right-0 top-full mt-2 w-72 bg-white rounded-xl border border-slate-200 shadow-lg z-50 overflow-hidden">
                {/* Profile Header */}
                <div className="bg-gradient-to-br from-blue-500 to-indigo-600 px-5 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-2xl bg-white/20 flex items-center justify-center font-black text-white text-lg">
                      {admin?.name?.[0] || 'A'}
                    </div>
                    <div>
                      <div className="font-bold text-white">{admin?.name}</div>
                      <div className="text-xs text-blue-100">{admin?.email}</div>
                    </div>
                  </div>
                </div>

                {/* Profile Details */}
                <div className="px-5 py-3 space-y-2">
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-400 font-medium">Tipo</span>
                    <span className="font-bold text-slate-700">Global Master</span>
                  </div>
                  <div className="flex justify-between text-xs">
                    <span className="text-slate-400 font-medium">Cargo</span>
                    <span className="font-bold text-slate-700">{(admin as any)?.role === 'admin' ? 'Administrador' : 'Operador'}</span>
                  </div>
                </div>

                {/* Logout */}
                <div className="border-t border-slate-100 px-4 py-3">
                  <Button
                    variant="ghost"
                    className="w-full justify-start rounded-lg font-bold gap-2 text-destructive hover:bg-red-50 hover:text-destructive"
                    onClick={() => { setProfileOpen(false); logout(); }}
                  >
                    <LogOut size={16} /> Sair do Painel
                  </Button>
                </div>
              </div>
            )}
          </div>
        </header>

        <div className="flex-1 overflow-auto p-6 bg-gray-50 dark:bg-zinc-900 text-gray-900 dark:text-zinc-100">
          <Outlet />
        </div>
      </main>
    </div>
  );
};
