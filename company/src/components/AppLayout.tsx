import React, { useState } from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { useAuthStore } from '../store/auth.store';
import { 
  LayoutDashboard, Users, UsersRound, Settings, 
  FileBarChart, LogOut, User, Menu, X, ChevronDown 
} from 'lucide-react';
import { Button } from './ui/button';
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuLabel, 
  DropdownMenuSeparator, 
  DropdownMenuTrigger 
} from './ui/dropdown-menu';

export const AppLayout: React.FC = () => {
  const { user, logout } = useAuthStore();
  const [isSidebarOpen, setIsSidebarOpen] = useState(false);

  const navLinks = [
    { to: "/dashboard", icon: <LayoutDashboard size={20} />, label: "Painel" },
    { to: "/members", icon: <Users size={20} />, label: "Membros" },
    { to: "/groups", icon: <UsersRound size={20} />, label: "Grupos de Estudo" },
    { to: "/reports", icon: <FileBarChart size={20} />, label: "Relatórios" },
    { to: "/settings", icon: <Settings size={20} />, label: "Configurações" },
  ];

  const handleLogout = () => {
    logout();
  };

  return (
    <div className="flex h-screen bg-slate-50 dark:bg-slate-900 overflow-hidden">
      {/* Mobile Sidebar Overlay */}
      {isSidebarOpen && (
        <div 
          className="fixed inset-0 bg-black/50 z-40 lg:hidden backdrop-blur-sm"
          onClick={() => setIsSidebarOpen(false)}
        />
      )}

      {/* Sidebar (Desktop & Mobile) */}
      <aside className={`
        fixed inset-y-0 left-0 w-64 bg-white dark:bg-slate-950 border-r border-slate-200 dark:border-slate-800 
        flex flex-col shadow-xl z-50 transition-transform duration-300 lg:relative lg:translate-x-0
        ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}
      `}>
        <div className="h-16 flex items-center justify-between px-4 border-b border-slate-200 dark:border-slate-800">
          <h1 className="text-lg font-bold text-primary truncate max-w-[180px]">
            {user?.company_name || 'Minha Instituição'}
          </h1>
          <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setIsSidebarOpen(false)}>
            <X size={20} />
          </Button>
        </div>
        
        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          {navLinks.map((link) => (
            <NavLink
              key={link.to}
              to={link.to}
              onClick={() => setIsSidebarOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-xl transition-all ${
                  isActive
                    ? "bg-primary text-white shadow-md shadow-primary/20 font-semibold"
                    : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800"
                }`
              }
            >
              {link.icon}
              {link.label}
            </NavLink>
          ))}
        </nav>
        
        <div className="p-4 border-t border-slate-100 dark:border-slate-800">
           <div className="flex items-center gap-3 px-2 mb-4">
              <div className="w-8 h-8 rounded-full bg-primary/10 flex items-center justify-center text-primary font-bold text-xs">
                 {user?.company_name?.[0] || 'I'}
              </div>
              <div className="flex-1 truncate">
                 <p className="text-[10px] text-slate-400 uppercase font-bold tracking-widest leading-none">Instituição</p>
                 <p className="text-sm font-semibold truncate text-slate-700 dark:text-slate-300">{user?.company_name}</p>
              </div>
           </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col overflow-hidden relative">
        <header className="h-16 bg-white/80 backdrop-blur-md border-b border-slate-200 dark:bg-slate-950/80 dark:border-slate-800 flex items-center justify-between px-4 lg:px-8 z-30 sticky top-0">
           <div className="flex items-center gap-3">
              <Button variant="ghost" size="icon" className="lg:hidden" onClick={() => setIsSidebarOpen(true)}>
                 <Menu size={22} />
              </Button>
              <h2 className="font-bold text-lg text-slate-800 dark:text-slate-100 hidden sm:block">Painel de Liderança</h2>
           </div>

           <div className="flex items-center gap-4">
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="h-10 px-3 pl-4 flex items-center gap-3 rounded-full hover:bg-slate-100 transition-all border border-slate-100">
                    <span className="text-sm font-medium text-slate-700">
                       Olá, <strong className="text-secondary">{user?.name}</strong>
                    </span>
                    <div className="w-8 h-8 rounded-full bg-secondary/20 flex items-center justify-center text-secondary font-black text-xs">
                       {user?.name?.[0] || 'P'}
                    </div>
                    <ChevronDown size={14} className="text-slate-400" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56 mt-1 rounded-2xl p-2 border-slate-200 shadow-2xl">
                  <DropdownMenuLabel className="font-normal p-3">
                    <div className="flex flex-col space-y-1">
                      <p className="text-sm font-bold leading-none">{user?.name}</p>
                      <p className="text-xs leading-none text-muted-foreground">{user?.email}</p>
                    </div>
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator className="bg-slate-100 mx-2" />
                  <DropdownMenuItem className="rounded-lg p-3 cursor-pointer py-2 focus:bg-slate-50">
                    <User className="mr-3 h-4 w-4 text-slate-400" />
                    <span>Meu Perfil</span>
                  </DropdownMenuItem>
                  <DropdownMenuItem className="rounded-lg p-3 cursor-pointer py-2 focus:bg-slate-50" onClick={() => (window.location.href = '/settings')}>
                    <Settings className="mr-3 h-4 w-4 text-slate-400" />
                    <span>Configurações</span>
                  </DropdownMenuItem>
                  <DropdownMenuSeparator className="bg-slate-100 mx-2" />
                  <DropdownMenuItem className="rounded-lg p-3 cursor-pointer py-2 text-destructive focus:bg-destructive/10 focus:text-destructive" onClick={handleLogout}>
                    <LogOut className="mr-3 h-4 w-4" />
                    <span className="font-bold tracking-tight">Encerrar Sessão</span>
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
           </div>
        </header>

        <div className="flex-1 overflow-auto p-4 lg:p-10 text-slate-900 dark:text-slate-100 pb-20">
          <Outlet />
        </div>
      </main>
    </div>
  );
};
